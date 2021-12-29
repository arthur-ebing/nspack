# frozen_string_literal: true

module MasterfilesApp
  class AdvancedClassificationsRepo < BaseRepo
    build_for_select :ripeness_codes,
                     label: :ripeness_code,
                     value: :id,
                     no_active_check: true,
                     order_by: :ripeness_code

    build_for_select :rmt_handling_regimes,
                     label: :regime_code,
                     value: :id,
                     no_active_check: true,
                     order_by: :regime_code

    build_for_select :rmt_codes,
                     label: :rmt_code,
                     value: :id,
                     no_active_check: true,
                     order_by: :rmt_code

    build_for_select :rmt_variants,
                     label: :rmt_variant_code,
                     value: :id,
                     no_active_check: true,
                     order_by: :rmt_variant_code

    build_for_select :rmt_classification_types,
                     label: :rmt_classification_type_code,
                     value: :id,
                     no_active_check: true,
                     order_by: :rmt_classification_type_code

    build_for_select :rmt_classifications,
                     label: :rmt_classification,
                     value: :id,
                     no_active_check: true,
                     order_by: :rmt_classification

    crud_calls_for :rmt_classifications, name: :rmt_classification, wrapper: RmtClassification
    crud_calls_for :rmt_classification_types, name: :rmt_classification_type, wrapper: RmtClassificationType
    crud_calls_for :rmt_variants, name: :rmt_variant, wrapper: RmtVariant
    crud_calls_for :rmt_codes, name: :rmt_code, wrapper: RmtCode
    crud_calls_for :rmt_handling_regimes, name: :rmt_handling_regime, wrapper: RmtHandlingRegime
    crud_calls_for :ripeness_codes, name: :ripeness_code, wrapper: RipenessCode

    def find_ripeness_code_flat(id)
      hash = find_with_association(
        :ripeness_codes, id,
        lookup_functions: [{ function: :fn_current_status, args: ['ripeness_codes', :id], col_name: :status }]
      )
      return nil if hash.nil?

      RipenessCodeFlat.new(hash)
    end

    def find_rmt_handling_regime_flat(id)
      hash = find_with_association(
        :rmt_handling_regimes, id,
        lookup_functions: [{ function: :fn_current_status, args: ['rmt_handling_regimes', :id], col_name: :status }]
      )
      return nil if hash.nil?

      RmtHandlingRegimeFlat.new(hash)
    end

    def rmt_code_grid_row(where)
      query = <<~SQL
        select rmt_codes.id, commodities.code, cultivar_groups.cultivar_group_code, cultivars.cultivar_name, cultivars.id as cultivar_id
        , rmt_variants.rmt_variant_code, rmt_codes.rmt_code, rmt_codes.description, rmt_handling_regimes.regime_code
        , rmt_handling_regimes.for_packing
        , rmt_variants.id as rmt_variant_id
        ,(select string_agg(marketing_variety_code::text, ',')
        from marketing_varieties_for_cultivars
        join cultivars c on c.id = marketing_varieties_for_cultivars.cultivar_id
        join marketing_varieties on marketing_varieties.id=marketing_varieties_for_cultivars.marketing_variety_id
        where c.id=cultivars.id) as marketing_variety_code
        from cultivars
        left outer join rmt_variants ON rmt_variants.cultivar_id = cultivars.id
        left outer join rmt_codes ON rmt_codes.rmt_variant_id = rmt_variants.id
        left outer join cultivar_groups ON cultivar_groups.id = cultivars.cultivar_group_id
        left outer join commodities ON commodities.id = cultivar_groups.commodity_id
        left outer join rmt_handling_regimes ON rmt_handling_regimes.id = rmt_codes.rmt_handling_regime_id
        #{where}
      SQL
      DB[query].first
    end

    def rmt_classifications_grid_row(where)
      query = <<~SQL
        SELECT "rmt_classifications"."id", "rmt_classifications"."rmt_classification", "rmt_classification_types"."id" AS rmt_classification_type_id
        , "rmt_classification_types"."rmt_classification_type_code", "rmt_classification_types"."description", "rmt_classifications"."created_at"
        , "rmt_classifications"."updated_at", fn_current_status('rmt_classifications', "rmt_classifications"."id") AS status
        FROM "rmt_classification_types"
        LEFT JOIN "rmt_classifications" ON "rmt_classification_types"."id" = "rmt_classifications"."rmt_classification_type_id"
        #{where}
      SQL
      DB[query].first
    end

    def find_rmt_variant_cultivar_name(id)
      DB[:rmt_variants]
        .join(:cultivars, id: :cultivar_id)
        .where(Sequel[:rmt_variants][:id] => id)
        .get(:cultivar_name)
    end

    def classification_belongs_to_bin?(id)
      !DB[:rmt_bins]
        .where(Sequel.lit(" #{id} = ANY (rmt_classifications)"))
        .first.nil?
    end

    def find_rmt_variant_flat(id)
      hash = find_with_association(
        :rmt_variants, id,
        parent_tables: [{ parent_table: :cultivars,  foreign_key: :cultivar_id,
                          flatten_columns: { cultivar_name: :cultivar_name } }]
      )
      return nil if hash.nil?

      RmtVariantFlat.new(hash)
    end

    def for_select_rmt_codes_for_delivery(delivery_id)
      DB[:rmt_variants]
        .join(:rmt_codes, rmt_variant_id: :id)
        .join(:rmt_deliveries, cultivar_id: Sequel[:rmt_variants][:cultivar_id])
        .where(Sequel[:rmt_deliveries][:id] => delivery_id)
        .select(:rmt_code, Sequel[:rmt_codes][:id])
        .map(%i[rmt_code id])
    end

    def for_select_rmt_classifications_for_type(rmt_classification_type_code)
      DB[:rmt_classifications]
        .join(:rmt_classification_types, id: :rmt_classification_type_id)
        .where(rmt_classification_type_code: rmt_classification_type_code)
        .select(:rmt_classification, Sequel[:rmt_classifications][:id])
        .map(%i[rmt_classification id])
    end

    def type_code_for_classification(classification_id)
      DB[:rmt_classifications]
        .join(:rmt_classification_types, id: :rmt_classification_type_id)
        .where(Sequel[:rmt_classifications][:id] => classification_id)
        .get(:rmt_classification_type_code)
    end
  end
end
