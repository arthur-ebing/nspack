# frozen_string_literal: true

module ProductionApp
  module Job
    class RecalculateBinNettWeight < BaseQueJob
      attr_reader :repo, :user_name

      self.maximum_retry_count = 0

      def run(params) # rubocop:disable Metrics/AbcSize
        @repo = ProductionApp::ReworksRepo.new
        @user_name = params[:user_name]

        begin
          repo.transaction do
            res = ProductionApp::RecalcBinsNettWeight.call(params)

            if res.success
              send_bus_message('Re-calculated bins nett weight successfully', message_type: :information, target_user: user_name)
            else
              msg = res.instance.empty? ? res.message : "\n#{res.message}\n#{res.instance}"
              ErrorMailer.send_error_email(subject: 'Re-calculate bins nett weight failed',
                                           message: msg)
              send_bus_message('Re-calculate bins nett weight failed', message_type: :error, target_user: user_name)
            end
            finish
          end
        rescue StandardError => e
          ErrorMailer.send_exception_email(e, subject: 'Re-calculate bins nett weight')
          send_bus_message("Failed to re-calculate bins nett weight - #{e.message}", message_type: :error, target_user: user_name)
          expire
        end
      end
    end
  end
end
