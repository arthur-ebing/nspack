# frozen_string_literal: true

module MesscadaApp
  # Given a bin asset number and device, get the run number
  # and check that the bin meets the criteria for tipping on that ran.
  class CanTipBin < BaseService
    include BinTipSupport

    attr_reader :repo, :bin_number, :device, :production_run_id, :run_attrs, :legacy_errors

    def initialize(bin_number, device)
      @repo = MesscadaRepo.new
      @bin_number = bin_number
      @device = device
      @legacy_errors = []
    end

    def call # rubocop:disable Metrics/AbcSize
      run_res = active_run_for_device
      return run_res unless run_res.success

      @production_run_id = run_res.instance
      @run_attrs = repo.get_run_setup_reqs(production_run_id)

      errors = check_basic_validations
      return failed_response(errors) unless errors.nil?

      stock_type_id = repo.get_id(:stock_types, stock_type_code: AppConst::BIN_STOCK_TYPE)
      return failed_response("Cannot move BIN #{bin_number}. BIN is on a tripsheet") if repo.exists?(:vehicle_job_units,
                                                                                                     stock_type_id: stock_type_id,
                                                                                                     stock_item_id: rmt_bin[:id],
                                                                                                     offloaded_at: nil)

      if AppConst::CR_PROD.kromco_rmt_integration?
        res = check_valid_bin_for_kromco_rmt_system
        return res unless res.success
      end

      run_stats_bins_tipped = repo.get_run_bins_tipped(production_run_id)
      success_response('RMT Bin is valid for tipping', run_attrs.merge(rmt_bin_id: rmt_bin[:id], run_id: production_run_id, bins_tipped: run_stats_bins_tipped))
    end

    private

    def check_basic_validations
      return "Bin:#{bin_number} could not be found" unless bin_exists?
      return "Bin:#{bin_number} has already been tipped" if bin_tipped?
      return "Bin:#{bin_number} scrapped" if bin_scrapped?

      validate_setup_requirements
    end

    def validate_setup_requirements # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      check = repo.check_bin_in_wip(bin_number)
      return check.message unless check.success

      check = check_farm_match
      return check.message unless check.success

      check = check_orchard_match
      return check.message unless check.success

      check = check_cultivar_group_match
      return check.message unless check.success

      check = check_cultivar_match
      return check.message unless check.success

      check = check_mrl_result_status
      return check.message unless check.success

      nil
    end

    def check_farm_match # rubocop:disable Metrics/AbcSize
      # puts "FARM: #{rmt_bin[:farm_id]} == #{run_attrs[:farm_id]}"
      return ok_response if rmt_bin[:farm_id] == run_attrs[:farm_id]

      msg = "INVALID FARM: Run requires: #{run_attrs[:farm_code]}. Bin is: #{rmt_bin[:farm_code]}"

      # If the rule allows us to match on farm group, make sure both groups are the same and neither of them are nil:
      return failed_response(msg) unless AppConst::CR_PROD.bintip_allow_farms_of_same_group_to_match?
      return ok_response if farm_groups_match?([rmt_bin[:farm_id], run_attrs[:farm_id]])

      failed_response(msg)
    end

    def farm_groups_match?(farm_ids)
      grp_ids = repo.select_values(:farms, :farm_group_id, id: farm_ids)
      grp_ids.compact.length > 1 && grp_ids.first == grp_ids.last
    end

    def check_orchard_match
      return ok_response if rmt_bin[:orchard_id] == run_attrs[:orchard_id]
      return ok_response if run_attrs[:allow_orchard_mixing]

      failed_response("INVALID ORCHARD: Run requires: #{run_attrs[:orchard_code]}. Bin is: #{rmt_bin[:orchard_code]}")
    end

    def check_cultivar_group_match
      return ok_response if rmt_bin[:cultivar_group_id] == run_attrs[:cultivar_group_id]
      return ok_response if run_attrs[:allow_cultivar_group_mixing]

      failed_response("INVALID CULTIVAR GROUP: Run requires: #{run_attrs[:cultivar_group_code]}. Bin is: #{rmt_bin[:cultivar_group_code]}")
    end

    def check_cultivar_match
      return ok_response if rmt_bin[:cultivar_id] == run_attrs[:cultivar_id]
      return ok_response if run_attrs[:allow_cultivar_mixing]

      failed_response("INVALID CULTIVAR: Run requires: #{run_attrs[:cultivar_name]}. Bin is: #{rmt_bin[:cultivar_name]}")
    end

    # Kromco DP checks
    def check_valid_bin_for_kromco_rmt_system # rubocop:disable Metrics/AbcSize
      legacy_bintip_criteria = repo.get(:production_runs, :legacy_bintip_criteria, production_run_id)
      return failed_response("Bin Tipping Criteria Not Setup For Run:#{production_run_id}") unless legacy_bintip_criteria

      legacy_bintip_criteria.select { |_, v| v == 't' }.each_key do |check|
        next if %w[farm_code commodity_code rmt_variety_code].include?(check) # Not yet written...

        send("bintip_criteria_check_#{check}".to_sym)
      end
      return ok_response if legacy_errors.empty?

      failed_response("Tipping Criteria Fails for bin #{bin_number}: #{legacy_errors.join(' ')}")
    end

    LEGACY_ERROR_MSG = '%s is %s on run, but %s on bin.'

    def bintip_criteria_check_colour_percentage
      # log_code_check('Colour', run_attrs[:colour_percentage], rmt_bin[:colour_percentage])
      return if rmt_bin[:colour_percentage_id] == run_attrs[:colour_percentage_id]

      legacy_errors << format(LEGACY_ERROR_MSG, 'Colour', run_attrs[:colour_percentage] || 'blank', rmt_bin[:colour_percentage] || 'blank')
    end

    def bintip_criteria_check_rmt_size
      # log_code_check('Size', run_attrs[:size_code], rmt_bin[:size_code])
      return if rmt_bin[:rmt_size_id] == run_attrs[:rmt_size_id]

      legacy_errors << format(LEGACY_ERROR_MSG, 'Size', run_attrs[:size_code] || 'blank', rmt_bin[:size_code] || 'blank')
    end

    def bintip_criteria_check_product_class_code
      # log_code_check('Class', run_attrs[:class_code], rmt_bin[:class_code])
      return if run_attrs[:rmt_class_id] == rmt_bin[:rmt_class_id]

      legacy_errors << format(LEGACY_ERROR_MSG, 'Class', run_attrs[:class_code] || 'blank', rmt_bin[:class_code] || 'blank')
    end

    def bintip_criteria_check_season_code
      # log_code_check('Season', run_attrs[:season_id], rmt_bin[:season_id])
      return if run_attrs[:season_id] == rmt_bin[:season_id]

      season_codes = repo.select_values(:seasons, :season_code, id: [run_attrs[:season_id], rmt_bin[:season_id]])
      legacy_errors << format(LEGACY_ERROR_MSG, 'Season', *season_codes)
    end

    def bintip_criteria_check_rmt_code
      # log_code_check('Rmt Code', run_attrs[:rmt_code], rmt_bin[:rmt_code])
      return if rmt_bin[:rmt_code_id] == run_attrs[:rmt_code_id]

      legacy_errors << format(LEGACY_ERROR_MSG, 'RMT Code', run_attrs[:rmt_code] || 'blank', rmt_bin[:rmt_code] || 'blank')
    end

    def bintip_criteria_check_actual_cold_treatment
      # log_code_check('Cold Treatment', run_attrs[:actual_cold_treatment_code], rmt_bin[:actual_cold_treatment_code])
      return if rmt_bin[:actual_cold_treatment_id] == run_attrs[:actual_cold_treatment_id]

      legacy_errors << format(LEGACY_ERROR_MSG, 'Cold Treatment', run_attrs[:actual_cold_treatment_code] || 'blank', rmt_bin[:actual_cold_treatment_code] || 'blank')
    end

    def bintip_criteria_check_actual_ripeness_treatment
      # log_code_check('Ripeness Treatment', run_attrs[:actual_ripeness_treatment_code], rmt_bin[:actual_ripeness_treatment_code])
      return if rmt_bin[:actual_ripeness_treatment_id] == run_attrs[:actual_ripeness_treatment_id]

      legacy_errors << format(LEGACY_ERROR_MSG, 'Ripeness Treatment', run_attrs[:actual_ripeness_treatment_code] || 'blank', rmt_bin[:actual_ripeness_treatment_code] || 'blank')
    end

    # def log_code_check(name, run_val, bin_val)
    #   puts ">>> #{name} - R: #{run_val || 'nil'} -> B: #{bin_val || 'nil'}"
    # end

    def rmt_bin
      @rmt_bin ||= RawMaterialsApp::RmtDeliveryRepo.new.find_flat_bin_by_asset_number(bin_number)
    end

    def bin_exists?
      !rmt_bin.nil?
    end

    def bin_tipped?
      return false if rmt_bin.nil?

      !rmt_bin[:bin_tipped_date_time].nil?
    end

    def bin_scrapped?
      rmt_bin[:scrapped]
    end

    def check_mrl_result_status
      return ok_response unless AppConst::CR_RMT.enforce_mrl_check?

      delivery_id = repo.get(:rmt_bins, :rmt_delivery_id, rmt_bin[:id])
      unless delivery_id.nil_or_empty?
        res = QualityApp::FailedAndPendingMrlResults.call(delivery_id)
        return res unless res.success
      end
      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end
  end
end
