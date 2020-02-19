# frozen_string_literal: true

module MasterfilesApp
  class OrchardTestTypeInteractor < BaseInteractor
    def create_orchard_test_type(params) # rubocop:disable Metrics/AbcSize
      res = validate_orchard_test_type_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_orchard_test_type(res)
        log_status(:orchard_test_types, id, 'CREATED')
        log_transaction
      end
      instance = orchard_test_type(id)
      success_response("Created orchard test type #{instance.test_type_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { test_type_code: ['This orchard test type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_orchard_test_type(id, params)
      res = validate_orchard_test_type_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_orchard_test_type(id, res)
        log_transaction
      end
      instance = orchard_test_type(id)
      success_response("Updated orchard test type #{instance.test_type_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_orchard_test_type(id)
      name = orchard_test_type(id).test_type_code
      repo.transaction do
        repo.delete_orchard_test_type(id)
        log_status(:orchard_test_types, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted orchard test type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::OrchardTestType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= OrchardTestRepo.new
    end

    def orchard_test_type(id)
      repo.find_orchard_test_type(id)
    end

    def validate_orchard_test_type_params(params)
      OrchardTestTypeSchema.call(params)
    end
  end
end
