module MesscadaApp
  class StagingOverride < BaseService
    attr_reader :repo, :delivery_repo, :locn_repo, :bins, :plant_resource_code

    def initialize(bins, plant_resource_code)
      @repo = RawMaterialsApp::PresortStagingRunRepo.new
      @delivery_repo = RawMaterialsApp::RmtDeliveryRepo.new
      @locn_repo = MasterfilesApp::LocationRepo.new
      @bins = bins.compact
      @plant_resource_code = plant_resource_code
    end

    def call
      repo.transaction do
        stage_current_active_child_run
        new_active_child_run
        StageBins.call(bins, plant_resource_code)

        res = StageBins.result(results)
        success_response('staging result', res)
      end
    rescue StandardError => e
      failed_response('error', StageBins.error_xml(e.message))
    end

    private

    def stage_current_active_child_run
      id = repo.running_child_run_for_plant_resource(plant_resource_code)
      repo.update_presort_staging_run_child(id, staged: true, running: false, staged_at: Time.now)
      repo.log_status(:presort_staging_run_children, id, 'STAGED')
    end

    def new_active_child_run
      active_pre_sort_stagin_run_id = repo.running_runs_for_plant_resource(plant_resource_code).first
      farm_id = repo.get_value(:rmt_bins, :farm_id, bin_asset_number: bins[0])
      id = repo.create_presort_staging_run_child(created_at: Time.now,
                                                 activated_at: Time.now,
                                                 presort_staging_run_id: active_pre_sort_stagin_run_id,
                                                 farm_id: farm_id,
                                                 running: true,
                                                 created_from_override: true)
      repo.log_status(:presort_staging_run_children, id, 'RUNNING')
    end

    def results
      res = []
      bins.each_with_index do |b, i|
        res << { bin_num: b, bin_item: i + 1, status: 'OVERRIDDEN' }
      end
      res
    end
  end
end
