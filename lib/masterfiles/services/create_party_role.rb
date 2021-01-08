# frozen_string_literal: true

module MasterfilesApp
  class CreatePartyRole < BaseService
    attr_reader :repo, :user, :params, :party_role_id, :role_id, :person_id, :organization_id, :party_id

    def initialize(role, params, user)
      @repo = PartyRepo.new
      @user = user
      @params = params
      @party_role_id = params["#{role.downcase}_party_role_id".to_sym]
      raise Crossbeams::InfoError, 'party_role_id nil' if party_role_id.nil?

      @role_id = repo.get_id(:roles, name: role)
      raise Crossbeams::InfoError, "Role: #{role} not defined." if role_id.nil?

      @params[:role_ids] = [role_id]
    end

    def call # rubocop:disable Metrics/AbcSize
      case party_role_id
      when 'O'
        res = create_organization
        return res unless res.success
      when 'P'
        res = create_person
        return res unless res.success
      else
        add_role_to_party
      end
      party_role_id = repo.get_id(:party_roles, role_id: role_id, person_id: person_id, organization_id: organization_id)
      party_role_id ||= repo.get_id(:party_roles, role_id: role_id, party_id: party_id)

      success_response('Created Party Role', OpenStruct.new(party_role_id: party_role_id))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def add_role_to_party
      @party_id = DB[:party_roles].where(id: party_role_id).get(:party_id)
      return if repo.exists?(:party_roles, id: party_role_id, role_id: role_id)

      repo.add_role_to_party(party_id, role_id)
    end

    def create_organization
      res = OrganizationSchema.call(params)
      return validation_failed_response(res) if res.failure?

      @organization_id = repo.create_organization(res)
      success_response('Created organization')
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { medium_description: ['This organization already exists'] }))
    end

    def create_person
      res = PersonSchema.call(params)
      return validation_failed_response(res) if res.failure?

      @person_id = repo.create_person(res)
      success_response('Created person')
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { first_name: ['This person already exists'] }))
    end
  end
end
