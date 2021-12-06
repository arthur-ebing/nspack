# frozen_string_literal: true

module RawMaterialsApp
  module Job
    class PresortIntegrationQueue < BaseQueJob
      self.maximum_retry_count = 0

      def single_instance_job
        'presort_integration_queue'
      end

      def run(bin_number, unit, request_path, event)
        if event == 'create'
          AppConst::PRESORT_BIN_CREATED_LOG.info("#{request_path}&bin=#{bin_number}&unit=#{unit}")
          MesscadaApp::PresortBinCreated.call(bin_number, unit)
        elsif event == 'tipped'
          AppConst::PRESORT_BIN_TIPPED_LOG.info("#{request_path}&bin=#{bin_number}")
          MesscadaApp::PresortBinTipped.call(bin_number, unit)
        else
          raise 'Event(create/tipped) not specified for presort_integration_queue entry.'
        end

        finish
      end
    end
  end
end
