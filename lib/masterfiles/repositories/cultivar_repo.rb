# frozen_string_literal: true

module MasterfilesApp
  class CultivarRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :cultivar_groups,
                     label: :cultivar_group_code,
                     value: :id,
                     order_by: :cultivar_group_code
    build_inactive_select :cultivar_groups,
                          label: :cultivar_group_code,
                          value: :id,
                          order_by: :cultivar_group_code

    build_for_select :cultivars,
                     label: :cultivar_name,
                     value: :id,
                     order_by: :cultivar_name
    build_inactive_select :cultivars,
                          label: :cultivar_name,
                          value: :id,
                          order_by: :cultivar_name

    build_for_select :marketing_varieties,
                     label: :marketing_variety_code,
                     value: :id,
                     order_by: :marketing_variety_code
    build_inactive_select :marketing_varieties,
                          label: :marketing_variety_code,
                          value: :id,
                          order_by: :marketing_variety_code

    crud_calls_for :cultivar_groups, name: :cultivar_group
    crud_calls_for :cultivars, name: :cultivar, exclude: %i[delete]
    crud_calls_for :marketing_varieties, name: :marketing_variety, wrapper: MarketingVariety, exclude: %i[create delete]

    def find_cultivar_group(id)
      hash = find_with_association(
        :cultivar_groups, id,
        parent_tables: [{ parent_table: :commodities,
                          flatten_columns: { code: :commodity_code } }]
      )
      return nil if hash.nil?

      hash[:cultivar_ids] = DB[:cultivars].where(cultivar_group_id: id).select_map(:id)
      hash[:cultivars] = DB[:cultivars].where(cultivar_group_id: id).select_map(:cultivar_name)
      CultivarGroup.new(hash)
    end

    def find_cultivar(id)
      hash = find_with_association(
        :cultivars, id,
        parent_tables: [{ parent_table: :cultivar_groups,
                          flatten_columns: { cultivar_group_code: :cultivar_group_code, commodity_id: :commodity_id } },
                        { parent_table: :commodities,
                          flatten_columns: { code: :commodity_code } }]
      )
      return nil if hash.nil?

      hash[:marketing_varieties] = DB[:marketing_varieties]
                                   .join(:marketing_varieties_for_cultivars, marketing_variety_id: :id)
                                   .where(cultivar_id: id)
                                   .select_map(:marketing_variety_code)
      Cultivar.new(hash)
    end

    def find_cultivar_by_variant_and_commodity_and_orchard(variant_code, commodity_code, orchard_id)
      hash = DB["SELECT cultivars.id
         FROM masterfile_variants v
         join cultivars on cultivars.id=v.masterfile_id
         JOIN cultivar_groups ON cultivar_groups.id = cultivars.cultivar_group_id
         JOIN commodities ON commodities.id = cultivar_groups.commodity_id
         JOIN orchards ON cultivars.id = ANY (orchards.cultivar_ids)
         WHERE variant_code = ? and commodities.code= ? and orchards.id = ?", variant_code, commodity_code, orchard_id].first

      hash.nil? ? nil : hash[:id]
    end

    def find_cultivar_by_cultivar_name_and_commodity_and_orchard(cultivar_name, commodity_code, orchard_id)
      hash = DB["SELECT cultivars.id
         FROM cultivars
         JOIN cultivar_groups ON cultivar_groups.id = cultivars.cultivar_group_id
         JOIN commodities ON commodities.id = cultivar_groups.commodity_id
         JOIN orchards ON cultivars.id = ANY (orchards.cultivar_ids)
         WHERE cultivar_name = ? and commodities.code= ? and orchards.id = ?", cultivar_name, commodity_code, orchard_id].first

      hash.nil? ? nil : hash[:id]
    end

    def delete_cultivar(id)
      DB[:marketing_varieties_for_cultivars].where(cultivar_id: id).delete
      delete_orphaned_marketing_varieties
      DB[:cultivars].where(id: id).delete
    end

    def create_marketing_variety(cultivar_id, attrs)
      id = DB[:marketing_varieties].insert(attrs.to_h)
      DB[:marketing_varieties_for_cultivars].insert(cultivar_id: cultivar_id, marketing_variety_id: id)
      id
    end

    def link_marketing_varieties(cultivar_id, marketing_variety_ids)
      existing_ids      = cultivar_marketing_variety_ids(cultivar_id)
      old_ids           = existing_ids - marketing_variety_ids
      new_ids           = marketing_variety_ids - existing_ids

      DB[:marketing_varieties_for_cultivars].where(cultivar_id: cultivar_id).where(marketing_variety_id: old_ids).delete
      delete_orphaned_marketing_varieties

      new_ids.each do |prog_id|
        DB[:marketing_varieties_for_cultivars].insert(cultivar_id: cultivar_id, marketing_variety_id: prog_id)
      end
      { success: true }
    end

    def delete_orphaned_marketing_varieties
      link_ids = DB[:marketing_varieties_for_cultivars].select_map(:marketing_variety_id)
      marketing_variety_ids = DB[:marketing_varieties].select_map(:id)
      orphan_ids = marketing_variety_ids - link_ids
      DB[:customer_variety_varieties].where(marketing_variety_id: orphan_ids).delete
      DB[:customer_varieties].where(variety_as_customer_variety_id: orphan_ids).delete
      DB[:marketing_varieties].where(id: orphan_ids).delete
    end

    def cultivar_marketing_variety_ids(cultivar_id)
      DB[:marketing_varieties_for_cultivars].where(cultivar_id: cultivar_id).select_map(:marketing_variety_id).sort
    end

    def delete_marketing_variety(id)
      DB[:marketing_varieties_for_cultivars].where(marketing_variety_id: id).delete
      DB[:marketing_varieties].where(id: id).delete
    end

    def for_select_cultivar_marketing_varieties(id)
      DB[:marketing_varieties]
        .join(:marketing_varieties_for_cultivars, marketing_variety_id: :id)
        .select(Sequel[:marketing_varieties][:id], :marketing_variety_code)
        .where(cultivar_id: id)
        .order(:marketing_variety_code)
        .map(%i[marketing_variety_code id])
    end

    def for_select_cultivar_group_marketing_varieties(id)
      DB[:marketing_varieties]
        .join(:marketing_varieties_for_cultivars, marketing_variety_id: :id)
        .join(:cultivars, id: :cultivar_id)
        .select(Sequel[:marketing_varieties][:id], :marketing_variety_code)
        .where(cultivar_group_id: id)
        .order(:marketing_variety_code)
        .map(%i[marketing_variety_code id])
    end

    def find_marketing_variety_by_cultivar_code(cultivar_id)
      query = <<~SQL
        SELECT id
        FROM marketing_varieties
        WHERE marketing_variety_code IN (SELECT cultivar_name
                                         from cultivars
                                         where id = ? )
      SQL
      DB[query, cultivar_id].get(:id)
    end

    def find_production_run_cultivar(production_run_id)
      DB[:cultivars]
        .join(:production_runs, cultivar_id: :id)
        .where(Sequel[:production_runs][:id] => production_run_id)
        .get(:cultivar_name)
    end

    def for_select_cultivar_codes(where: {}, exclude: {})
      dataset = DB[:cultivars]
                .join(:cultivar_groups, id: :cultivar_group_id)
                .where(convert_empty_values(where))
                .exclude(convert_empty_values(exclude))
      label_name = %i[cultivar_name cultivar_code]
      dataset.select(*label_name, Sequel[:cultivars][:id]).map { |rec| [label_name.map { |nm| rec[nm] }.join(' - '), rec[:id]] }
    end
  end
end
