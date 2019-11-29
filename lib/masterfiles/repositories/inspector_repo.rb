# frozen_string_literal: true

module MasterfilesApp
  class InspectorRepo < BaseRepo
    build_for_select :inspectors,
                     label: :tablet_ip_address,
                     value: :id,
                     order_by: :tablet_ip_address
    build_inactive_select :inspectors,
                          label: :tablet_ip_address,
                          value: :id,
                          order_by: :tablet_ip_address

    crud_calls_for :inspectors, name: :inspector, wrapper: Inspector

    def find_inspector_flat(id)
      hash = find_with_association(:inspectors, id)
      return nil if hash.nil?

      hash[:inspector] = MasterfilesApp::PartyRepo.new.find_party_role(hash[:inspector_party_role_id])&.party_name
      InspectorFlat.new(hash)
    end

    def for_select_inspectors
      ds = DB[:inspectors]
      ds = ds.select(:id, Sequel.function(:fn_party_role_name, :inspector_party_role_id))
      ds.map { |r| [r[:fn_party_role_name], r[:id]] }
    end
  end
end
