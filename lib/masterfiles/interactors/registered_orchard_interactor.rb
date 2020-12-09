# frozen_string_literal: true

module MasterfilesApp
  class RegisteredOrchardInteractor < BaseInteractor
    def create_registered_orchard(params) # rubocop:disable Metrics/AbcSize
      res = validate_registered_orchard_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_registered_orchard(res)
        log_status(:registered_orchards, id, 'CREATED')
        log_transaction
      end
      instance = registered_orchard(id)
      success_response("Created registered orchard #{instance.orchard_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { orchard_code: ['This registered orchard already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_registered_orchard(id, params)
      res = validate_registered_orchard_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_registered_orchard(id, res)
        log_transaction
      end
      instance = registered_orchard(id)
      success_response("Updated registered orchard #{instance.orchard_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_registered_orchard(id) # rubocop:disable Metrics/AbcSize
      name = registered_orchard(id).orchard_code
      repo.transaction do
        repo.delete_registered_orchard(id)
        log_status(:registered_orchards, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted registered orchard #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete registered orchard. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::RegisteredOrchard.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= FarmRepo.new
    end

    def registered_orchard(id)
      repo.find_registered_orchard(id)
    end

    def validate_registered_orchard_params(params)
      RegisteredOrchardSchema.call(params)
    end
  end
end
