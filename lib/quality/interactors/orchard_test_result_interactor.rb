# frozen_string_literal: true

module QualityApp
  class OrchardTestResultInteractor < BaseInteractor
    def phyt_clean_request(puc_ids = nil)
      service_res = nil
      repo.transaction do
        service_res = QualityApp::PhytCleanStandardData.call(puc_ids)
        raise Crossbeams::InfoError, service_res.message unless service_res.success

        log_transaction
      end
      service_res
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_orchard_test_results
      ids = repo.select_values(:orchard_test_types, :id)
      service_res = nil
      ids.each do |id|
        repo.transaction do
          service_res = RefreshOrchardTestResults.call(id)
          raise Crossbeams::InfoError, service_res.message unless service_res.success

          log_transaction
        end
      end
      service_res
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_orchard_test_result(id, params) # rubocop:disable Metrics/AbcSize
      res = OrchardTestUpdateSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        service_res = QualityApp::UpdateOrchardTestResult.call(id, res)
        raise Crossbeams::InfoError, service_res.message unless service_res.success

        log_transaction
      end
      instance = repo.find_orchard_test_result_flat(id)
      success_response("Updated orchard test result #{instance.orchard_test_type_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_orchard_test_result(id)
      name = orchard_test_result(id).orchard_test_type_code
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
      repo.find_orchard_test_result_flat(id)
    end
  end
end
