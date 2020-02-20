# frozen_string_literal: true

module QualityApp
  class OrchardTestResultInteractor < BaseInteractor
    def create_orchard_test_result(params) # rubocop:disable Metrics/AbcSize
      res = validate_orchard_test_result_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_orchard_test_result(res)
        log_status(:orchard_test_results, id, 'CREATED')
        log_transaction
      end
      instance = orchard_test_result(id)
      success_response("Created orchard test result #{instance.description}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { description: ['This orchard test result already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_orchard_test_result(id, params)
      res = validate_orchard_test_result_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_orchard_test_result(id, res)
        log_transaction
      end
      instance = orchard_test_result(id)
      success_response("Updated orchard test result #{instance.description}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_orchard_test_result(id)
      name = orchard_test_result(id).description
      repo.transaction do
        repo.delete_orchard_test_result(id)
        log_status(:orchard_test_results, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted orchard test result #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::OrchardTestResult.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= OrchardTestRepo.new
    end

    def orchard_test_result(id)
      repo.find_orchard_test_result(id)
    end

    def validate_orchard_test_result_params(params)
      OrchardTestResultSchema.call(params)
    end
  end
end
