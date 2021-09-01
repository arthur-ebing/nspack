# frozen_string_literal: true

module RawMaterialsApp
  module Job
    class BinIntegrationQueueProcessor < BaseQueJob
      self.maximum_retry_count = 0

      def run(job_no)
        RawMaterialsApp::RmtDeliveryRepo.new.transaction do
          RawMaterialsApp::BinIntegrationQueueProcessor.call(job_no)

          finish
        end
      end
    end
  end
end
