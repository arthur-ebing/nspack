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

    crud_calls_for :rmt_container_types, name: :rmt_container_type, wrapper: RmtContainerType

    def find_inner_container_types(where_clause)
      DB["SELECT *
          FROM rmt_container_types
          WHERE #{where_clause}"].map { |o| [o[:container_type_code], o[:id]] }
    end

    def find_container_type(id)
      hash = find_hash(:rmt_container_types, id)
      return nil if hash.nil?

      RmtContainerType.new(hash)
    end
  end
end
