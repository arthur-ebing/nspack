module MesscadaApp
  class BinStaging < BaseService
    attr_reader :repo, :delivery_repo, :locn_repo, :messcada_repo, :bins, :plant_resource_code, :active_presort_staging_run_id, :active_presort_staging_run_child_id, :bin_ids_map, :current_validation_bin, :staging_run

    def initialize(bins, plant_resource_code)
      @repo = RawMaterialsApp::PresortStagingRunRepo.new
      @delivery_repo = RawMaterialsApp::RmtDeliveryRepo.new
      @locn_repo = MasterfilesApp::LocationRepo.new
      @messcada_repo = MesscadaApp::MesscadaRepo.new
      @bins = bins.compact
      @plant_resource_code = plant_resource_code
      @bin_ids_map = {}
    end

    def call # rubocop:disable Metrics/AbcSize,  Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      repo.transaction do
        res = validate_active_run
        return res unless res.success

        res = validate_active_child_run
        return res unless res.success

        validations = validate_bins
        statuses = validations.map { |v| v[:status] }.uniq.sort

        if statuses == %w[OK]
          StageBins.call(bins, plant_resource_code)
        elsif statuses == %w[OK REQ_OVERRIDE].sort
          ok_and_req_override_rule(validations)
        elsif !statuses.include?('FAILED') && statuses.include?('REQ_OVERRIDE')
          req_override_and_no_failures_rule(validations)
        else
          errors_rule(validations)
        end

        res = StageBins.result(validations)
        success_response('staging result', res)
      end
    rescue StandardError => e
      failed_response('error', StageBins.error_xml(e.message))
    end

    private

    def ok_and_req_override_rule(validations)
      validations.each do  |v|
        if v[:status] == 'REQ_OVERRIDE'
          v[:status] = 'FAILED'
          v[:errs] = [v[:msg].sub('Start new run?', 'Cannot override').to_s]
        elsif v[:status] == 'OK'
          v[:status] = 'FAILED'
          v[:errs] = ['bin OK, but other bins do not have the same farm as the child_run']
        end
      end
    end

    def req_override_and_no_failures_rule(validations)
      overriddes = validations.find_all { |v| v[:status] == 'REQ_OVERRIDE' }
      bin_numbers = validations.map { |v| v[:bin_num] }
      return unless overriddes.length > 1 && !repo.select_values(:rmt_bins, :farm_id, bin_asset_number: bin_numbers).uniq.one?

      overriddes.each do |o|
        o[:status] = 'FAILED'
        o[:errs] = ["All bins must have the same farm[#{repo.bin_farm(o[:bin_num])}]"]
      end
    end

    def errors_rule(validations)
      validations.each do |v|
        v[:errs] = [v[:msg].sub('Start new run?', 'Cannot override').to_s] if v[:status] == 'REQ_OVERRIDE'
        v[:errs] = ['bin OK, but other bins have failed'] if v[:status] == 'OK'
        v[:status] = 'FAILED'
      end
    end

    def validate_active_run
      active_pre_sort_stagin_runs = repo.running_runs_for_plant_resource(plant_resource_code)
      return failed_response('error', StageBins.error_xml("No active pre_sort_run could be found for presort_unit: #{plant_resource_code}")) if active_pre_sort_stagin_runs.empty?
      return failed_response('error', StageBins.error_xml("#{active_pre_sort_stagin_runs.size} active pre_sort_runs found for presort_unit: #{plant_resource_code}")) unless active_pre_sort_stagin_runs.one?

      @active_presort_staging_run_id = active_pre_sort_stagin_runs.first
      @staging_run = repo.find_presort_staging_run_flat(@active_presort_staging_run_id)
      ok_response
    end

    def validate_active_child_run
      active_pre_sort_stagin_run_children = repo.select_values(:presort_staging_run_children, :id, presort_staging_run_id: active_presort_staging_run_id, running: true)
      return failed_response('error', StageBins.error_xml("No active child could be found for pre_sort_run: #{active_presort_staging_run_id}")) if active_pre_sort_stagin_run_children.empty?
      return failed_response('error', StageBins.error_xml("#{active_pre_sort_stagin_run_children.size} active children found for pre_sort_run: #{active_presort_staging_run_id}")) unless active_pre_sort_stagin_run_children.one?

      @active_presort_staging_run_child_id = active_pre_sort_stagin_run_children.first
      ok_response
    end

    def validate_bins
      validations = []
      bins.each_with_index do |bin, i|
        errors = valid_bin?(bin)
        validation = { bin_num: bin, bin_item: i + 1 }
        validations << if errors
                         { errs: errors, status: 'FAILED' }.merge(validation)
                       else
                         valid_bin_for_active_child_run?(bin).merge(validation)
                       end
      end
      validations
    end

    def valid_bin?(asset_number) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      err = bin_exists?(asset_number)
      return [err] unless err.nil?

      errors = []
      err = bin_from_ra7?(asset_number)
      errors << err unless err.nil?

      check = messcada_repo.check_bin_in_wip(asset_number)
      errors << check.message  unless check.success

      delivery_id = repo.get_value(:rmt_bins, :rmt_delivery_id, bin_asset_number: asset_number)
      unless delivery_id.nil_or_empty?
        res = QualityApp::FailedAndPendingMrlResults.call(delivery_id)
        errors << res.message unless res.success
      end

      errs = valid_bin_for_active_parent_run?(asset_number)
      errors += errs unless errs.nil?

      err = rebin?(asset_number)
      errors << err unless err.nil?

      err = not_on_sale?(asset_number)
      errors << err unless err.nil?

      errors unless errors.empty?
    end

    def rebin?(asset_number)
      return "Bin: #{asset_number} is a rebin" if current_validation_bin[:production_run_rebin_id]
    end

    def not_on_sale?(asset_number)
      return "Bin: #{asset_number} is on sale" if current_validation_bin[:bin_load_product_id]
    end

    def bin_exists?(asset_number)
      @current_validation_bin = repo.find_bin_record_by_asset_number(asset_number)
      return "Bin:#{asset_number} does not exist" unless current_validation_bin

      bin_ids_map.store(asset_number, current_validation_bin[:id])
      return "Bin:#{asset_number} has been tipped" unless current_validation_bin[:tipped_asset_number].nil_or_empty?
      return "Bin:#{asset_number} has been shipped" unless current_validation_bin[:shipped_asset_number].nil_or_empty?
    end

    def bin_from_ra7?(asset_number)
      bin_location_id = current_validation_bin[:location_id]
      ra7_id = repo.get_value(:locations, :id, location_long_code: 'RA7')
      return "Bin:#{asset_number} is from RA7" if locn_repo.belongs_to_parent?(bin_location_id, ra7_id)
    end

    def valid_bin_for_active_child_run?(asset_number)
      run_farm_code = repo.child_run_farm(active_presort_staging_run_child_id)
      bin_farm_code = repo.bin_farm(asset_number)
      validations = {}
      if bin_farm_code == run_farm_code || run_farm_code == '0P'
        validations[:status] = 'OK'
      else
        validations[:status] = 'REQ_OVERRIDE'
        validations[:msg] = "Bin:#{asset_number} belongs to farm [#{bin_farm_code}], but child_run's farm is [#{run_farm_code}]. Start new run?"
      end
      validations
    end

    VALID_BIN_ERROR_MSG = '%s is %s on bin, but %s on run.'.freeze

    def valid_bin_for_active_parent_run?(asset_number) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      errs = []
      errs << format(VALID_BIN_ERROR_MSG, 'season_code', current_validation_bin.season_code || 'blank', staging_run.season_code || 'blank') if current_validation_bin.season_id != staging_run.season_id
      errs << format(VALID_BIN_ERROR_MSG, 'cultivar_name', current_validation_bin.cultivar_name || 'blank', staging_run.cultivar_name || 'blank') if current_validation_bin.cultivar_id != staging_run.cultivar_id
      errs << format(VALID_BIN_ERROR_MSG, 'colour', current_validation_bin.colour_percentage || 'blank', staging_run.colour_percentage || 'blank') if staging_run.colour_percentage_id && current_validation_bin.colour_percentage_id != staging_run.colour_percentage_id
      errs << format(VALID_BIN_ERROR_MSG, 'cold_treatment_code', current_validation_bin.actual_cold_treatment_code || 'blank', staging_run.actual_cold_treatment_code || 'blank') if staging_run.actual_cold_treatment_id && current_validation_bin.actual_cold_treatment_id != staging_run.actual_cold_treatment_id
      errs << format(VALID_BIN_ERROR_MSG, 'ripeness_treatment_code', current_validation_bin.actual_ripeness_treatment_code || 'blank', staging_run.actual_ripeness_treatment_code || 'blank') if staging_run.actual_ripeness_treatment_id && current_validation_bin.actual_ripeness_treatment_id != staging_run.actual_ripeness_treatment_id
      errs << format(VALID_BIN_ERROR_MSG, 'rmt_code', current_validation_bin.rmt_code || 'blank', staging_run.rmt_code || 'blank') if staging_run.rmt_code_id && current_validation_bin.rmt_code_id != staging_run.rmt_code_id
      errs << format(VALID_BIN_ERROR_MSG, 'rmt_class_code', current_validation_bin.class_code || 'blank', staging_run.rmt_class_code || 'blank') if staging_run.rmt_class_id && current_validation_bin.rmt_class_id != staging_run.rmt_class_id
      errs << format(VALID_BIN_ERROR_MSG, 'size_code', current_validation_bin.size_code || 'blank', staging_run.size_code || 'blank') if staging_run.rmt_size_id && current_validation_bin.rmt_size_id != staging_run.rmt_size_id
      errs << "bin location_code[#{current_validation_bin.location_long_code}] is not in [RA_6 or RA_7 or PRESORT]" unless valid_bin_location_for_staging?(asset_number)
      return errs unless errs.empty?
    end

    def valid_bin_location_for_staging?(asset_number)
      bin_location_id = repo.get_value(:rmt_bins, :location_id, bin_asset_number: asset_number)
      ra_6_id = repo.get_value(:locations, :id, location_long_code: 'RA_6')
      ra_7_id = repo.get_value(:locations, :id, location_long_code: 'RA_7')
      presort_id = repo.get_value(:locations, :id, location_long_code: 'PRESORT')
      locn_repo.belongs_to_parent?(bin_location_id, ra_6_id) || locn_repo.belongs_to_parent?(bin_location_id, ra_7_id) || locn_repo.belongs_to_parent?(bin_location_id, presort_id)
    end
  end
end
