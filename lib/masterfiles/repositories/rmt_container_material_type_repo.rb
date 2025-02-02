# frozen_string_literal: true

module MasterfilesApp
  class RmtContainerMaterialTypeRepo < BaseRepo
    build_for_select :rmt_container_material_types,
                     label: :container_material_type_code,
                     value: :id,
                     order_by: :container_material_type_code
    build_inactive_select :rmt_container_material_types,
                          label: :container_material_type_code,
                          value: :id,
                          order_by: :container_material_type_code

    crud_calls_for :rmt_container_material_types, name: :rmt_container_material_type, wrapper: RmtContainerMaterialType

    def find_bin_rmt_container_material_type(bin_asset_number)
      qry = <<~SQL
        select ct.id, cm.container_material_type_code
        from rmt_bins b
        join rmt_container_types ct on ct.id=b.rmt_container_type_id
        join rmt_container_material_types cm on cm.rmt_container_type_id=ct.id
        where b.bin_asset_number=? or b.tipped_asset_number=?
        order by b.id desc
      SQL
      DB[qry, bin_asset_number, bin_asset_number].first
    end

    def find_rmt_container_material_type(id)
      hash = find_with_association(
        :rmt_container_material_types, id,
        parent_tables: [{ parent_table: :rmt_container_types, foreign_key: :rmt_container_type_id,
                          flatten_columns: { container_type_code: :rmt_container_type } }]
      )
      return nil if hash.nil?

      hash[:party_role_ids] = party_role_ids(hash[:id])
      hash[:container_material_owners] = container_material_owners(hash[:id])
      RmtContainerMaterialType.new(hash)
    end

    def party_role_ids(rmt_container_material_type_id)
      DB["SELECT pr.id
                FROM rmt_container_material_owners co
                JOIN party_roles pr on pr.id=co.rmt_material_owner_party_role_id
                LEFT OUTER JOIN organizations o ON o.id = pr.organization_id
                LEFT OUTER JOIN people p ON p.id = pr.person_id
                LEFT OUTER JOIN roles r ON r.id = pr.role_id
                WHERE co.rmt_container_material_type_id = ?", rmt_container_material_type_id].map { |o| o[:id] }
    end

    def container_material_owners(rmt_container_material_type_id)
      DB[:rmt_container_material_owners]
        .select(Sequel.function(:fn_party_role_name_with_role, :rmt_material_owner_party_role_id))
        .where(rmt_container_material_type_id: rmt_container_material_type_id)
        .order(Sequel.function(:fn_party_role_name_with_role, :rmt_material_owner_party_role_id))
        .map(:fn_party_role_name_with_role)
    end

    def get_current_rmt_material_container_owners(rmt_container_material_type_id)
      DB[:rmt_container_material_owners].where(rmt_container_material_type_id: rmt_container_material_type_id)
    end

    def delete_rmt_material_container_owners(rmt_material_container_owners, party_role_ids)
      rmt_material_container_owners.where(rmt_material_owner_party_role_id: party_role_ids).delete
    end

    def create_rmt_material_container_owner(rmt_container_material_type_id, rmt_material_owner_party_role_id)
      DB[:rmt_container_material_owners].insert(rmt_container_material_type_id: rmt_container_material_type_id, rmt_material_owner_party_role_id: rmt_material_owner_party_role_id)
    end

    def delete_rmt_container_material_type(id)
      DB[:rmt_container_material_owners].where(rmt_container_material_type_id: id).delete
      DB[:rmt_container_material_types].where(id: id).delete
    end

    def create_rmt_container_material_type(attrs)
      params = attrs.to_h
      party_role_ids = params.delete(:party_role_ids)
      party_role_ids ||= []
      # return { error: { roles: ['You did not choose a party role'] } } if party_role_ids.empty?

      rmt_container_material_type_id = DB[:rmt_container_material_types].insert(params)
      party_role_ids.each do |pr_id|
        DB[:rmt_container_material_owners].insert(rmt_container_material_type_id: rmt_container_material_type_id,
                                                  rmt_material_owner_party_role_id: pr_id)
      end
      rmt_container_material_type_id
    end
  end
end
