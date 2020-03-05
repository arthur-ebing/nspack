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

    def find_inspector_flat(id) # rubocop:disable Metrics/AbcSize
      hash = find_hash(:inspectors, id)
      return nil if hash.nil?

      party_role_id = hash[:inspector_party_role_id]
      hash = hash.merge(find_hash(:party_roles, party_role_id).reject { |k, _| k == :id })
      hash = hash.merge(party_repo.find_person(hash[:person_id]).to_h.reject { |k, _| k == :id })
      hash[:inspector] = party_repo.find_party_role(party_role_id)&.party_name # fn_party_role_name
      InspectorFlat.new(hash)
    end

    def for_select_inspectors
      ds = DB[:inspectors]
      ds = ds.select(:id, Sequel.function(:fn_party_role_name, :inspector_party_role_id))
      ds.map { |r| [r[:fn_party_role_name], r[:id]] }
    end

    def create_inspector(attrs) # rubocop:disable Metrics/AbcSize
      params = attrs.to_h
      person_params = PersonSchema.call(params)
      raise Crossbeams::InfoError, person_params.messages unless person_params.messages.empty?

      role_id = params[:role_ids].first
      # find person
      person_id = DB[:people].where(surname: params[:surname],
                                    first_name: params[:first_name],
                                    title: params[:title]).get(:id)

      if person_id.nil?
        person_id = party_repo.create_person(person_params)
      else
        party_repo.append_role(person_id, role_id, 'P')
      end

      params[:inspector_party_role_id] = get_id(:party_roles, person_id: person_id, role_id: role_id)
      inspector_params = InspectorSchema.call(params)
      raise Crossbeams::InfoError, inspector_params.messages unless inspector_params.messages.empty?

      create(:inspectors, inspector_params)
    end

    def delete_inspector(id)
      party_role_id = DB[:inspectors].where(id: id).get(:inspector_party_role_id)
      person_id = DB[:party_roles].where(id: party_role_id).get(:person_id)
      role_ids = DB[:party_roles].where(person_id: person_id).select_map(:role_id)

      delete(:inspectors, id)
      delete(:party_roles, party_role_id)
      party_repo.delete_person(person_id) if role_ids.length == 1
    end

    def party_repo
      @party_repo ||= PartyRepo.new
    end
  end
end
