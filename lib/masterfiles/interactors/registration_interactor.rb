# frozen_string_literal: true

module MasterfilesApp
  class RegistrationInteractor < BaseInteractor
    def create_registration(params) # rubocop:disable Metrics/AbcSize
      res = validate_registration_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_registration(res)
        log_status(:registrations, id, 'CREATED')
        log_transaction
      end
      instance = registration(id)
      success_response("Created registration #{instance.registration_type}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { registration_type: ['There already exists a registration for this type.'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_registration(id, params)
      res = validate_registration_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_registration(id, res)
        log_transaction
      end
      instance = registration(id)
      success_response("Updated registration #{instance.registration_type}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_registration(id) # rubocop:disable Metrics/AbcSize
      name = registration(id).registration_type
      repo.transaction do
        repo.delete_registration(id)
        log_status(:registrations, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted registration #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete registration. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Registration.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= PartyRepo.new
    end

    def registration(id)
      repo.find_registration(id)
    end

    def validate_registration_params(params)
      RegistrationSchema.call(params)
    end
  end
end
