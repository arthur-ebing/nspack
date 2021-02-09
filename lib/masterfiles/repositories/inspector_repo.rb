# frozen_string_literal: true

module MasterfilesApp
  class InspectorRepo < BaseRepo
    # INSPECTORS
    # --------------------------------------------------------------------------
    def for_select_inspectors
      DB[:inspectors]
        .select(:id, Sequel.function(:fn_party_role_name, :inspector_party_role_id))
        .map { |r| [r[:fn_party_role_name], r[:id]] }
    end

    build_inactive_select :inspectors, label: :tablet_ip_address, value: :id, order_by: :tablet_ip_address

    crud_calls_for :inspectors, name: :inspector

    def find_inspector(id)
      hash = find_hash(:inspectors, id)
      return nil if hash.nil?

      hash[:inspector] = DB.get(Sequel.function(:fn_party_role_name, hash[:inspector_party_role_id]))
      Inspector.new(hash)
    end
  end
end
