# frozen_string_literal: true

module MasterfilesApp
  class SupplierRepo < BaseRepo
    build_for_select :supplier_groups, label: :supplier_group_code,  value: :id, order_by: :supplier_group_code
    build_inactive_select :supplier_groups, label: :supplier_group_code, value: :id, order_by: :supplier_group_code
    crud_calls_for :supplier_groups, name: :supplier_group, wrapper: SupplierGroup

    build_for_select :suppliers, label: :id, value: :id, order_by: :id
    build_inactive_select :suppliers, label: :id,  value: :id, order_by: :id
    crud_calls_for :suppliers, name: :supplier, wrapper: Supplier

    def find_supplier(id)
      query = <<~SQL
        SELECT
            suppliers.id,
            suppliers.supplier_party_role_id,
            fn_party_role_name(suppliers.supplier_party_role_id) AS supplier,
            suppliers.supplier_group_ids,
            array_agg(distinct supplier_group_code order by supplier_group_code) AS supplier_group_codes,
            suppliers.farm_ids,
            array_agg(distinct farm_code order by farm_code) AS farm_codes,
            suppliers.active

        FROM suppliers
        LEFT JOIN supplier_groups ON supplier_groups.id = ANY (suppliers.supplier_group_ids)
        LEFT JOIN farms ON farms.id = ANY (suppliers.farm_ids)
        WHERE suppliers.id = ?
        GROUP BY
            suppliers.id
      SQL
      hash = DB[query, id].first
      return nil if hash.nil?

      Supplier.new(DB[query, id].first)
    end

    def delete_supplier_group(id)
      query = <<~SQL
        SELECT suppliers.id
        FROM supplier_groups
        JOIN suppliers ON supplier_groups.id = ANY(suppliers.supplier_group_ids)
        WHERE supplier_groups.id = ?
      SQL
      raise Sequel::ForeignKeyConstraintViolation, OpenStruct.new(message: "Key (id)=(#{id}) is still referenced from table suppliers") unless DB[query, id].first.nil?

      delete(:supplier_groups, id)
    end
  end
end
