# frozen_string_literal: true

module ProductionApp
  module Job
    class ApplyDeliveriesOrchardChanges < BaseQueJob
      attr_reader :repo

      self.maximum_retry_count = 0

      def run(params)  # rubocop:disable Metrics/AbcSize
        @repo = ProductionApp::ReworksRepo.new
        change_attrs = params[0][:change_attrs]
        reworks_run_attrs = params[0][:reworks_run_attrs]

        begin
          repo.transaction do
            res = ProductionApp::ChangeDeliveriesOrchards.call(change_attrs, reworks_run_attrs)

            unless res.success
              msg = res.instance.empty? ? res.message : "\n#{res.message}\n#{res.instance}"
              ErrorMailer.send_error_email(subject: 'Apply Deliveries Orchard Changes failed',
                                           message: msg)
            end
            finish
          end
        rescue StandardError => e
          log_err(e.message)
          ErrorMailer.send_exception_email(e, subject: 'Apply Deliveries Orchard Changes')
          expire
        end
      end
    end
  end
end
