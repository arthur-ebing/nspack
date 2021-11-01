# frozen_string_literal: true

module MesscadaApp
  # Given a bin asset number and device, get the run number
  # and check that the bin meets the criteria for tipping on that ran.
  class CanTipBin < BaseService # rubocop:disable Metrics/ClassLength
    include BinTipSupport

    attr_reader :repo, :bin_number, :device, :production_run_id, :run_attrs, :run_criteria, :legacy_errors

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

    def validate_setup_requirements
      check = check_farm_match
      return check.message unless check.success

      check = check_orchard_match
      return check.message unless check.success

      check = check_cultivar_group_match
      return check.message unless check.success

      check = check_cultivar_match
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
      legacy_bintip_criteria, @run_criteria = repo.get(:production_runs, production_run_id, %i[legacy_bintip_criteria legacy_data])
      return failed_response("Bin Tipping Criteria Not Setup For Run:#{production_run_id}") unless legacy_bintip_criteria
      return failed_response("Bin Tipping Legacy Data Not Setup For Run:#{production_run_id}") unless run_criteria

      legacy_bintip_criteria.select { |_, v| v == 't' }.each_key do |check|
        next if %w[farm_code commodity_code rmt_variety_code rmt_product_type].include?(check) # Not yet written...

        send("legacy_check_#{check}".to_sym)
      end
      return ok_response if legacy_errors.empty?

      failed_response("Tipping Criteria Fails for bin #{bin_number}: #{legacy_errors.join(' ')}")
    end

    LEGACY_ERROR_MSG = '%s is %s on run, but %s on bin.'

    def legacy_check_treatment_code
      # log_code_check('Colour', run_criteria['treatment_code'], rmt_bin[:legacy_data]['colour'])
      return if run_criteria['treatment_code'] == rmt_bin[:legacy_data]['colour']

      legacy_errors << format(LEGACY_ERROR_MSG, 'Colour', run_criteria['treatment_code'] || 'blank', rmt_bin[:legacy_data]['colour'] || 'blank')
    end

    def legacy_check_rmt_size
      # log_code_check('Size', run_criteria['rmt_size'], rmt_bin[:size_code])
      return if run_criteria['rmt_size'] == rmt_bin[:size_code]

      legacy_errors << format(LEGACY_ERROR_MSG, 'Size', run_criteria['rmt_size'] || 'blank', rmt_bin[:size_code] || 'blank')
    end

    def legacy_check_product_class_code
      # log_code_check('Class', run_criteria['product_class_code'], rmt_bin[:class_code])
      return if run_criteria['product_class_code'] == rmt_bin[:class_code]

      legacy_errors << format(LEGACY_ERROR_MSG, 'Class', run_criteria['product_class_code'] || 'blank', rmt_bin[:class_code] || 'blank')
    end

    def legacy_check_pc_code
      # log_code_check('PC Code', run_criteria['pc_code'], rmt_bin[:legacy_data]['pc_code'])
      return if run_criteria['pc_code'] == rmt_bin[:legacy_data]['pc_name']

      legacy_errors << format(LEGACY_ERROR_MSG, 'PC Code', run_criteria['pc_code'] || 'blank', rmt_bin[:legacy_data]['pc_name'] || 'blank')
    end

    def legacy_check_cold_store_type
      # log_code_check('Cold store type', run_criteria['cold_store_type'], rmt_bin[:legacy_data]['cold_store_type'])
      return if run_criteria['cold_store_type'] == rmt_bin[:legacy_data]['cold_store_type']

      legacy_errors << format(LEGACY_ERROR_MSG, 'Cold store type', run_criteria['cold_store_type'] || 'blank', rmt_bin[:legacy_data]['cold_store_type'] || 'blank')
    end

    def legacy_check_season_code
      # log_code_check('Season', run_attrs[:season_id], rmt_bin[:season_id])
      return if run_attrs[:season_id] == rmt_bin[:season_id]

      season_codes = repo.select_values(:seasons, :season_code, id: [run_attrs[:season_id], rmt_bin[:season_id]])
      legacy_errors << format(LEGACY_ERROR_MSG, 'Season', *season_codes)
    end

    def legacy_check_track_indicator_code
      # log_code_check('Track indicator', run_criteria['track_indicator_code'], rmt_bin[:legacy_data]['track_slms_indicator_1_code'])
      return if run_criteria['track_indicator_code'] == rmt_bin[:legacy_data]['track_slms_indicator_1_code']

      legacy_errors << format(LEGACY_ERROR_MSG, 'Track indicator', run_criteria['track_indicator_code'] || 'blank', rmt_bin[:legacy_data]['track_slms_indicator_1_code'] || 'blank')
    end

    def legacy_check_ripe_point_code
      # log_code_check('Ripe point', run_criteria['ripe_point_code'], rmt_bin[:legacy_data]['ripe_point_code'])
      return if run_criteria['ripe_point_code'] == rmt_bin[:legacy_data]['ripe_point_code']

      legacy_errors << format(LEGACY_ERROR_MSG, 'Ripe point', run_criteria['ripe_point_code'] || 'blank', rmt_bin[:legacy_data]['ripe_point_code'] || 'blank')
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
  end
end
