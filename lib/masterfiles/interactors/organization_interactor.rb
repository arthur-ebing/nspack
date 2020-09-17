# frozen_string_literal: true

module MasterfilesApp
  class OrganizationInteractor < BaseInteractor
    def create_organization(params)
      res = validate_organization_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_organization(res)
      end
      instance = organization(id)
      success_response("Created organization #{instance.party_name}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { short_description: ['This organization already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_organization(id, params)
      res = validate_organization_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_organization(id, res)
      end
      instance = organization(id)
      success_response("Updated organization #{instance.party_name}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_organization(id)
      instance = organization(id)
      repo.transaction do
        repo.delete_organization(id)
      end
      success_response("Deleted organization #{instance.party_name}")
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete organization. Still referenced #{e.message.partition('referenced').last}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= PartyRepo.new
    end

    def organization(id)
      repo.find_organization(id)
    end

    def validate_organization_params(params)
      OrganizationSchema.call(params)
    end
  end
end
