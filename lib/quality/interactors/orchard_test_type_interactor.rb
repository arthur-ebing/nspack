# frozen_string_literal: true

module QualityApp
  class OrchardTestTypeInteractor < BaseInteractor
    def create_orchard_test_type(params) # rubocop:disable Metrics/AbcSize
      res = validate_orchard_test_type_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_orchard_test_type(res)
        service_res = CreateOrchardTestResults.call(id)
        raise Crossbeams::InfoError, service_res.message unless service_res.success

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

    def update_orchard_test_type(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_orchard_test_type_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_orchard_test_type(id, res)

        service_res = CreateOrchardTestResults.call(id)
        raise Crossbeams::InfoError, service_res.message unless service_res.success

        result_ids = repo.select_values(:orchard_test_results, :id, orchard_test_type_id: id)
        result_ids.each do |result_id|
          params = repo.find_hash(:orchard_test_results, result_id)
          params[:api_result] = res.to_h[:api_default_result]
          QualityApp::UpdateOrchardTestResult.call(result_id, params)
        end

        # id = service_res.instance.id
        log_transaction
      end
      instance = orchard_test_type(id)
      success_response("Updated orchard test type #{instance.test_type_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_orchard_test_type(id) # rubocop:disable Metrics/AbcSize
      name = orchard_test_type(id).test_type_code
      repo.transaction do
        result_ids = repo.select_values(:orchard_test_results, :id, orchard_test_type_id: id)
        result_ids.each do |result_id|
          freeze_result = repo.get(:orchard_test_results, result_id, :freeze_result)
          raise Crossbeams::InfoError, "Orchard Test Result #{result_id} frozen." if freeze_result

          repo.delete_orchard_test_result(result_id)
          log_status(:orchard_test_results, result_id, 'DELETED')
        end

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
      repo.find_orchard_test_type_flat(id)
    end

    def validate_orchard_test_type_params(params)
      OrchardTestTypeSchema.call(params)
    end
  end
end
