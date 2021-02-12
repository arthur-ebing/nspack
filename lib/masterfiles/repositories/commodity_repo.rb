# frozen_string_literal: true

module MasterfilesApp
  class CommodityRepo < BaseRepo
    build_for_select :commodity_groups,
                     label: :code,
                     value: :id,
                     order_by: :code
    build_inactive_select :commodity_groups,
                          label: :code,
                          value: :id

    build_for_select :commodities,
                     label: :code,
                     value: :id,
                     order_by: :code
    build_inactive_select :commodities,
                          label: :code,
                          value: :id

    crud_calls_for :commodity_groups, name: :commodity_group, wrapper: CommodityGroup, exclude: %i[delete]
    crud_calls_for :commodities, name: :commodity, exclude: %i[delete]

    def delete_commodity(id)
      dependents = DB[:cultivars].where(commodity_id: id).select_map(:id)
      return { error: 'This commodity is in use.' } unless dependents.empty?

      DB[:commodities].where(id: id).delete
      { success: true }
    end

    def delete_commodity_group(id)
      commodities = DB[:commodities].where(commodity_group_id: id).select_map(:id)
      dependents = DB[:cultivars].where(commodity_id: commodities).select_map(:id)
      return { error: 'Some commodities are in use.' } unless dependents.empty?

      commodities.each do |comm_id|
        delete_commodity(comm_id)
      end
      DB[:commodity_groups].where(id: id).delete
      { success: true }
    end

    def find_commodity(id)
      hash = find_with_association(:commodities,
                                   id,
                                   parent_tables: [{ parent_table: :commodity_groups,
                                                     columns: [:code],
                                                     flatten_columns: { code: :commodity_group_code } }])
      return nil if hash.nil?

      Commodity.new(hash)
    end
  end
end
