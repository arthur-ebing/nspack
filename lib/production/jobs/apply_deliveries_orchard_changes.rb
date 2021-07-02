# frozen_string_literal: true

module ProductionApp
  module Job
    class ApplyDeliveriesOrchardChanges < BaseQueJob
      attr_reader :repo, :user_name

      self.maximum_retry_count = 0

      def run(params) # rubocop:disable Metrics/AbcSize
        @repo = ProductionApp::ReworksRepo.new
        change_attrs = params[0][:change_attrs]
        reworks_run_attrs = params[0][:reworks_run_attrs]
        @user_name = reworks_run_attrs[:user_name]

        begin
          repo.transaction do
            res = ProductionApp::ChangeDeliveriesOrchards.call(change_attrs, reworks_run_attrs)

            if res.success
              send_bus_message('Reworks Cascading orchard change - Applying deliveries orchard changes was successful', message_type: :success, target_user: user_name)
            else
              msg = res.instance.empty? ? res.message : "\n#{res.message}\n#{res.instance}"
              ErrorMailer.send_error_email(subject: 'Apply Deliveries Orchard Changes failed',
                                           message: msg)
              send_bus_message('Reworks Cascading orchard change - Applying deliveries orchard changes failed', message_type: :error, target_user: user_name)
            end
            finish
          end
        rescue StandardError => e
          ErrorMailer.send_exception_email(e, subject: 'Apply Deliveries Orchard Changes')
          send_bus_message("Failed to Apply Deliveries Orchard Changes - #{e.message}", message_type: :error, target_user: user_name)
          expire
        end
      end
    end
  end
end
