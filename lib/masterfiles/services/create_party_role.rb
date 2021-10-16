# frozen_string_literal: true

module MasterfilesApp
  class CreatePartyRole < BaseService
    attr_reader :repo, :user, :party_role_id, :role_id
    attr_accessor :params

    def initialize(role, params, user, column_name: nil)
      @repo = PartyRepo.new
      @user = user
      @params = params
      col = column_name || "#{role.downcase}_party_role_id".to_sym
      @party_role_id = params[col]
      raise Crossbeams::InfoError, "#{col} has no value" if party_role_id.nil?

      params[:role_id] = repo.get_id(:roles, name: role)
      raise Crossbeams::InfoError, "Role: #{role} not defined." if params[:role_id].nil?

      params[:role_ids] = [params[:role_id]]
    end

    def call # rubocop:disable Metrics/AbcSize
      res = case party_role_id
            when 'Create New Organization'
              create_organization
            when 'Create New Person'
              create_person
            else
              create_party_role
            end
      return res unless res.success

      party_role_id ||= repo.get_id(:party_roles, role_id: params[:role_id], person_id: params[:person_id], organization_id: params[:organization_id])
      success_response('Created Party Role', OpenStruct.new(party_role_id: party_role_id))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def create_party_role # rubocop:disable Metrics/AbcSize
      params[:organization_id], params[:person_id], params[:party_id] = DB[:party_roles].where(id: party_role_id).get(%i[organization_id person_id party_id])
      return ok_response if repo.exists?(:party_roles, id: party_role_id, role_id: params[:role_id])

      res = PartyRoleSchema.call(params)
      return validation_failed_response(res) if res.failure?

      @party_role_id = repo.create_party_role(res)
      success_response('Created party role')
    end

    def create_organization
      res = OrganizationSchema.call(params)
      return validation_failed_response(res) if res.failure?

      params[:organization_id] = repo.create_organization(res)
      success_response('Created organization')
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { medium_description: ['This organization or short description already exists'] }))
    end

    def create_person
      res = PersonSchema.call(params.merge(vat_number: nil))
      return validation_failed_response(res) if res.failure?

      params[:person_id] = repo.create_person(res)
      success_response('Created person')
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { first_name: ['This person already exists'] }))
    end
  end
end
