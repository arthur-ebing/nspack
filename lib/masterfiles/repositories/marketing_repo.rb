# frozen_string_literal: true

module MasterfilesApp
  class MarketingRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :marks,
                     label: :mark_code,
                     value: :id,
                     order_by: :mark_code
    build_inactive_select :marks,
                          label: :mark_code,
                          value: :id,
                          order_by: :mark_code

    build_for_select :customer_varieties,
                     label: :id,
                     value: :id,
                     order_by: :id
    build_inactive_select :customer_varieties,
                          label: :id,
                          value: :id,
                          order_by: :id

    crud_calls_for :marks, name: :mark, wrapper: Mark
    crud_calls_for :customer_varieties, name: :customer_variety, wrapper: CustomerVariety

    def find_customer_variety(id)
      hash = find_with_association(:customer_varieties,
                                   id,
                                   parent_tables: [{ parent_table: :marketing_varieties,
                                                     columns: [:marketing_variety_code],
                                                     foreign_key: :variety_as_customer_variety_id,
                                                     flatten_columns: { marketing_variety_code: :variety_as_customer_variety } },
                                                   { parent_table: :target_market_groups,
                                                     columns: [:target_market_group_name],
                                                     foreign_key: :packed_tm_group_id,
                                                     flatten_columns: { target_market_group_name: :packed_tm_group } }],
                                   sub_tables: [{ sub_table: :customer_variety_varieties,
                                                  columns: [:marketing_variety_id] }])
      return nil if hash.nil?

      CustomerVariety.new(hash)
    end

    def find_customer_variety_variety(id)
      hash = find_with_association(:customer_variety_varieties,
                                   id,
                                   parent_tables: [{ parent_table: :marketing_varieties,
                                                     columns: [:marketing_variety_code],
                                                     foreign_key: :marketing_variety_id,
                                                     flatten_columns: { marketing_variety_code: :marketing_variety_code } }])
      return nil if hash.nil?

      OpenStruct.new(hash)
    end

    def create_customer_variety(attrs, marketing_variety_ids)
      params = attrs.to_h
      customer_variety_id = DB[:customer_varieties].insert(params)
      marketing_variety_ids.each do |marketing_variety_id|
        DB[:customer_variety_varieties].insert(customer_variety_id: customer_variety_id,
                                               marketing_variety_id: marketing_variety_id)
      end
      customer_variety_id
    end

    def associate_customer_variety_varieties(id, marketing_variety_ids)
      return { error: 'Choose at least one marketing variety' } if marketing_variety_ids.empty?

      existing_marketing_variety_ids = DB[:customer_variety_varieties].where(customer_variety_id: id).select_map(:marketing_variety_id)
      removed_marketing_variety_ids = existing_marketing_variety_ids - marketing_variety_ids
      new_marketing_variety_ids = marketing_variety_ids - existing_marketing_variety_ids
      DB[:customer_variety_varieties].where(customer_variety_id: id).where(marketing_variety_id: removed_marketing_variety_ids).delete
      new_marketing_variety_ids.each do |marketing_variety_id|
        DB[:customer_variety_varieties].insert(customer_variety_id: id,
                                               marketing_variety_id: marketing_variety_id)
      end
    end

    def clone_customer_variety(id, packed_tm_group_ids)
      return { error: 'Choose at least one packed tm group' } if packed_tm_group_ids.empty?

      marketing_variety_ids = DB[:customer_variety_varieties].where(customer_variety_id: id).select_map(:marketing_variety_id)
      return { error: 'Customer Variety cannot be cloned: should have at least one marketing variety' } if marketing_variety_ids.empty?

      packed_tm_group_ids.each do |packed_tm_group_id|
        customer_variety_attrs = {
          variety_as_customer_variety_id: find_hash(:customer_varieties, id)[:variety_as_customer_variety_id],
          packed_tm_group_id: packed_tm_group_id
        }
        create_customer_variety(customer_variety_attrs, marketing_variety_ids)
      end
    end

    def delete_customer_variety(id)
      DB[:customer_variety_varieties].where(customer_variety_id: id).delete
      DB[:customer_varieties].where(id: id).delete
      { success: true }
    end

    def delete_customer_variety_variety(id)
      DB[:customer_variety_varieties].where(id: id).delete
      { success: true }
    end

    def find_customer_variety_marketing_varieties(id)
      DB[:marketing_varieties]
        .join(:customer_variety_varieties, marketing_variety_id: :id)
        .where(customer_variety_id: id)
        .order(:marketing_variety_code)
        .select_map(:marketing_variety_code)
    end

    def find_customer_variety_marketing_variety(customer_variety_variety_id)
      DB[:marketing_varieties]
        .join(:customer_variety_varieties, marketing_variety_id: :id)
        .where(id: customer_variety_variety_id)
        .select_map(:marketing_variety_code)
    end

    def for_select_group_marketing_varieties(variety_as_customer_variety_id)
      cultivar_group_id = marketing_variety_cultivar_group(variety_as_customer_variety_id)
      DB[:marketing_varieties]
        .join(:marketing_varieties_for_cultivars, marketing_variety_id: :id)
        .join(:cultivars, id: :cultivar_id)
        .where(cultivar_group_id: cultivar_group_id)
        .select(
          :marketing_variety_id,
          :marketing_variety_code
        ).map { |r| [r[:marketing_variety_code], r[:marketing_variety_id]] }
    end

    def marketing_variety_cultivar_group(variety_as_customer_variety_id)
      DB[:marketing_varieties]
        .join(:marketing_varieties_for_cultivars, marketing_variety_id: :id)
        .join(:cultivars, id: :cultivar_id)
        .where(marketing_variety_id: variety_as_customer_variety_id)
        .select_map(:cultivar_group_id)
    end

    def marketing_variety_commodity(variety_as_customer_variety_id)
      DB[:marketing_varieties]
        .join(:marketing_varieties_for_cultivars, marketing_variety_id: :id)
        .join(:cultivars, id: :cultivar_id)
        .where(marketing_variety_id: variety_as_customer_variety_id)
        .get(:commodity_id)
    end

    def packed_tm_groups
      DB[:target_market_groups]
        .join(:target_market_group_types, id: :target_market_group_type_id)
        .where(target_market_group_type_code: AppConst::PACKED_TM_GROUP)
        .select_map(Sequel[:target_market_groups][:id])
    end

    def marketing_variety_packed_tm_groups(variety_as_customer_variety_id)
      DB[:customer_varieties]
        .where(variety_as_customer_variety_id: variety_as_customer_variety_id)
        .select_map(:packed_tm_group_id)
    end

    def available_to_clone_packed_tm_groups(variety_as_customer_variety_id)
      packed_tm_groups - marketing_variety_packed_tm_groups(variety_as_customer_variety_id)
    end

    def for_select_inactive_customer_varieties
      DB[:marketing_varieties]
        .join(:customer_varieties, variety_as_customer_variety_id: :id)
        .where(Sequel[:customer_varieties][:active] => false)
        .distinct(Sequel[:marketing_varieties][:id])
        .select(
          Sequel[:customer_varieties][:id],
          :marketing_variety_code
        ).map { |r| [r[:marketing_variety_code], r[:id]] }
    end

    def for_select_customer_varieties(packed_tm_group_id, marketing_variety_id)
      DB[:marketing_varieties]
        .join(:customer_varieties, variety_as_customer_variety_id: :id)
        .join(:customer_variety_varieties, customer_variety_id: :id)
        .where(packed_tm_group_id: packed_tm_group_id)
        .where(marketing_variety_id: marketing_variety_id)
        .distinct(Sequel[:marketing_varieties][:id])
        .select(
          Sequel[:customer_varieties][:id],
          :marketing_variety_code
        ).map { |r| [r[:marketing_variety_code], r[:id]] }
    end
  end
end
