# frozen_string_literal: true

module MasterfilesApp
  class SupplierRepo < BaseRepo
    build_for_select :supplier_groups,
                     label: :supplier_group_code,
                     value: :id,
                     order_by: :supplier_group_code
    build_inactive_select :supplier_groups,
                          label: :supplier_group_code,
                          value: :id,
                          order_by: :supplier_group_code
    crud_calls_for :supplier_groups, name: :supplier_group, wrapper: SupplierGroup, exclude: [:delete]

    build_for_select :suppliers,
                     label: :id,
                     value: :id,
                     order_by: :id
    build_inactive_select :suppliers,
                          label: :id,
                          value: :id,
                          order_by: :id
    crud_calls_for :suppliers, name: :supplier, exclude: [:delete]

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

    def delete_supplier(id)
      supplier_party_role_id = get(:suppliers, id, :supplier_party_role_id)
      delete(:suppliers, id)
      MasterfilesApp::PartyRepo.new.delete_party_role(supplier_party_role_id)
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

    def for_select_suppliers(where: {}, exclude: {}, active: true) # rubocop:disable Metrics/AbcSize
      DB[:suppliers]
        .join(:party_roles, id: :supplier_party_role_id)
        .join(:organizations, id: :organization_id)
        .where(Sequel[:suppliers][:active] => active)
        .where(convert_empty_values(where))
        .exclude(convert_empty_values(exclude))
        .distinct
        .select(Sequel[:suppliers][:id], Sequel[:organizations][:medium_description])
        .map { |r| [r[:medium_description], r[:id]] }
    end
  end
end
