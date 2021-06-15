# frozen_string_literal: true

module ProductionApp
  module Job
    class BulkTipBins < BaseQueJob
      def run(rw_run_id, bin_and_run_ids)
        repo = ProductionApp::ReworksRepo.new
        errors = []
        repo.transaction do
          bin_and_run_ids.each do |b|
            ProductionApp::ManuallyTipBins.call({ production_run_id: b[:run_id], pallets_selected: [b[:bin_id]] })
          rescue Crossbeams::InfoError => e
            errors << { suggested_tip_run_id: b[:run_id], id: b[:bin_id], error: e }
          end

          repo.update_reworks_run(rw_run_id, { errors: errors }) unless errors.empty?
          repo.update_reworks_run(rw_run_id, { bg_work_completed: true, completed_at: Time.now })
        end

        finish
      end
    end
  end
end
