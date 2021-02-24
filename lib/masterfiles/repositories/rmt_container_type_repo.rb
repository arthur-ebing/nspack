# frozen_string_literal: true

module MasterfilesApp
  class RmtContainerTypeRepo < BaseRepo
    build_for_select :rmt_container_types,
                     label: :container_type_code,
                     value: :id,
                     order_by: :container_type_code
    build_inactive_select :rmt_container_types,
                          label: :container_type_code,
                          value: :id,
                          order_by: :container_type_code

    crud_calls_for :rmt_container_types, name: :rmt_container_type

    def find_rmt_container_type(id)
      hash = find_with_association(:rmt_container_types, id,
                                   parent_tables: [{ parent_table: :rmt_container_types,
                                                     foreign_key: :rmt_inner_container_type_id,
                                                     columns: [:container_type_code],
                                                     flatten_columns: { container_type_code: :rmt_inner_container_type } }])
      return nil if hash.nil?

      RmtContainerType.new(hash)
    end
  end
end
