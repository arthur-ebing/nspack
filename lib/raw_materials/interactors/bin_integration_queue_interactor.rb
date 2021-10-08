# frozen_string_literal: true

module RawMaterialsApp
  class BinIntegrationQueueInteractor < BaseInteractor
    def reprocess_queue(queue_id)
      repo.transaction do
        repo.update(:bin_integration_queue, queue_id, job_no: nil, error: nil, is_bin_error: false, is_delivery_error: false)
        bins = repo.select_values(:bin_integration_queue, :bin_id, id: queue_id)
        success_response("legacy bins:#{bins.join(', ')} queued to be reprocessed")
      end
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= RawMaterialsApp::RmtDeliveryRepo.new
    end
  end
end
