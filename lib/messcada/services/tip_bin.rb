# frozen_string_literal: true

module MesscadaApp
  class TipBin < BaseService # rubocop:disable Metrics/ClassLength
    attr_reader :repo, :bin_number, :device, :run_id, :rmt_bin_id, :run_attrs

    def initialize(params)
      @repo = MesscadaRepo.new
      @bin_number = params[:bin_number]
      @device = params[:device]
    end

    def call # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      if !bin_exists? && AppConst::CR_PROD.kromco_rmt_integration?
        res = active_run_for_device
        return res unless res.success

        res = BinIntegration.call(bin_number, res.instance)
        return res unless res.success
      end

      if !bin_exists? && AppConst::CR_RMT.convert_carton_to_rebins? && repo.can_pallet_become_rebin?(bin_number)
        res = convert_carton_to_rebin
        return res unless res.success
      end

      errors = validations
      return failed_response(errors) unless errors.nil?

      location_to_id = ProductionApp::ResourceRepo.new.find_plant_resource(@run_attrs[:packhouse_resource_id]).location_id
      res = FinishedGoodsApp::MoveStockService.new(AppConst::BIN_STOCK_TYPE, rmt_bin_id, location_to_id, AppConst::BIN_TIP_MOVE_BIN_BUSINESS_PROCESS, nil).call
      return res unless res.success

      repo.complete_external_bin_tipping(bin_number, @run_id) if AppConst::CR_PROD.kromco_rmt_integration?

      update_bin

      run_stats_bins_tipped = repo.get_run_bins_tipped(@run_id)
      success_response('rmt bin tipped successfully', @run_attrs.merge(rmt_bin_id: @rmt_bin_id, run_id: @run_id, bins_tipped: run_stats_bins_tipped))
    end

    def can_tip_bin? # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      run_res = active_run_for_device
      return run_res unless run_res.success

      is_kr_bin = AppConst::CR_PROD.kromco_rmt_integration?
      if is_kr_bin
        res = BinIntegration.new(bin_number, run_res.instance).valid_bin_for_kromco_rmt_system?
        return res unless res.success
      end

      if !is_kr_bin || (is_kr_bin && bin_exists?)
        errors = validations
        return failed_response(errors) unless errors.nil?
      end

      run_stats_bins_tipped = repo.get_run_bins_tipped(run_res.instance)
      run_attrs = repo.get_run_setup_reqs(run_res.instance)
      success_response('rmt bin is valid for tipping', run_attrs.merge(rmt_bin_id: @rmt_bin_id, run_id: run_res.instance, bins_tipped: run_stats_bins_tipped))
    end

    private

    def scrap_src_pallets(pallet_numbers)
      attrs = { scrapped: true, scrapped_at: Time.now, exit_ref: AppConst::PALLET_EXIT_REF_SCRAPPED }
      reworks_run_booleans = { scrap_pallets: true }
      ProductionApp::ReworksRepo.new.scrapping_reworks_run(pallet_numbers, attrs, reworks_run_booleans, 'bin_tipping')

      ok_response
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def convert_carton_to_rebin # rubocop:disable Metrics/AbcSize
      seqs = repo.find_rebin_pallet_sequences(bin_number)
      return failed_response("Scanned pallet: #{bin_number} has more than one sequence") if seqs.size > 1

      s = seqs[0]
      attrs = { season_id: s[:season_id],
                cultivar_id: s[:cultivar_id],
                orchard_id: s[:orchard_id],
                farm_id: s[:farm_id],
                puc_id: s[:puc_id],
                rmt_class_id: s[:rmt_class_id] || MasterfilesApp::FruitRepo.new.find_rmt_class_by_grade(s[:grade_id]),
                rmt_container_type_id: repo.get_value(:rmt_container_types, :id, container_type_code: AppConst::DELIVERY_DEFAULT_RMT_CONTAINER_TYPE),
                cultivar_group_id: s[:cultivar_group_id],
                bin_fullness: AppConst::BIN_FULL,
                qty_bins: 1,
                bin_asset_number: bin_number,
                production_run_rebin_id: s[:production_run_id],
                nett_weight: s[:nett_weight],
                gross_weight: s[:gross_weight],
                location_id: ProductionApp::ResourceRepo.new.find_plant_resource(s[:packhouse_resource_id])[:location_id],
                is_rebin: true, converted_from_pallet_sequence_id: s[:id],
                rmt_size_id: MasterfilesApp::FruitSizeRepo.new.find_rmt_size_ref_by_fruit_size(s[:fruit_size_reference_id]) }

      res = RawMaterialsApp::RmtRebinBinSchema.call(attrs)
      return validation_failed_response(res) if res.failure?

      id = RawMaterialsApp::RmtDeliveryRepo.new.create_rmt_bin(res)
      repo.log_status(:rmt_bins, id, AppConst::CONVERTED_FROM_PALLET)
      repo.log_status(:pallets, s[:pallet_id], AppConst::CONVERTED_TO_REBIN)

      res = scrap_src_pallets([bin_number])
      return res unless res.success

      ok_response
    end

    def update_bin
      updates = { bin_tipped_date_time: Time.now, production_run_tipped_id: @run_id, exit_ref_date_time: Time.now, bin_tipped: true, exit_ref: 'TIPPED'  }
      updates.merge!(tipped_asset_number: bin_number, bin_asset_number: nil) if AppConst::USE_PERMANENT_RMT_BIN_BARCODES
      RawMaterialsApp::RmtDeliveryRepo.new.update_rmt_bin(@rmt_bin_id, updates)
    end

    def active_run_for_device
      line = ProductionApp::ResourceRepo.new.plant_resource_parent_of_system_resource(Crossbeams::Config::ResourceDefinitions::LINE, @device)
      return line unless line.success

      res = ProductionApp::ProductionRunRepo.new.find_production_runs_for_line_in_state(line.instance, running: true, tipping: true)
      return res unless res.success

      return failed_response('More than one tipping run on line') unless res.instance.length == 1

      success_response('run found', res.instance[0])
    end

    def validations # rubocop:disable Metrics/AbcSize
      return "Bin:#{bin_number} could not be found" unless bin_exists?
      return "Bin:#{bin_number} has already been tipped" if bin_tipped?
      return "Bin:#{bin_number} scrapped" if bin_scrapped?

      res = active_run_for_device
      return res.message unless res.success

      rmt_bin = find_rmt_bin
      run = ProductionApp::ProductionRunRepo.new.find_production_run(res.instance)

      @run_id = run[:id]
      @rmt_bin_id = rmt_bin[:id]
      if (setup_errors = validate_setup_requirements(rmt_bin[:id], run[:id]))
        return setup_errors
      end

      nil
    end

    def validate_setup_requirements(rmt_bin_id, run_id) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      bin_attrs = repo.get_rmt_bin_setup_reqs(rmt_bin_id)
      @run_attrs = repo.get_run_setup_reqs(run_id)

      if bin_attrs[:farm_id] != run_attrs[:farm_id]
        grp_ids = repo.select_values(:farms, :farm_group_id, id: [bin_attrs[:farm_id], run_attrs[:farm_id]])
        # If the rule allows us to match on farm group, make sure both groups are the same and neither of them are nil:
        return "INVALID FARM: Run requires: #{run_attrs[:farm_code]}. Bin is: #{bin_attrs[:farm_code]}" unless AppConst::CR_PROD.bintip_allow_farms_of_same_group_to_match? && grp_ids.compact.length > 1 && grp_ids.first == grp_ids.last
      end

      return "INVALID ORCHARD: Run requires: #{run_attrs[:orchard_code]}. Bin is: #{bin_attrs[:orchard_code]}" if !run_attrs[:allow_orchard_mixing] && (bin_attrs[:orchard_id] != run_attrs[:orchard_id])
      return "INVALID CULTIVAR GROUP: Run requires: #{run_attrs[:cultivar_group_code]}. Bin is: #{bin_attrs[:cultivar_group_code]}" if !run_attrs[:allow_cultivar_group_mixing] && (bin_attrs[:cultivar_group_id] != run_attrs[:cultivar_group_id])
      return "INVALID CULTIVAR: Run requires: #{run_attrs[:cultivar_name]}. Bin is: #{bin_attrs[:cultivar_name]}" if !run_attrs[:allow_cultivar_mixing] && (bin_attrs[:cultivar_id] != run_attrs[:cultivar_id])
    end

    def find_rmt_bin
      @find_rmt_bin ||= if AppConst::USE_PERMANENT_RMT_BIN_BARCODES
                          RawMaterialsApp::RmtDeliveryRepo.new.find_bin_by_asset_number(bin_number)
                        else
                          RawMaterialsApp::RmtDeliveryRepo.new.find_rmt_bin(bin_number)
                        end
    end

    def bin_exists?
      return false if find_rmt_bin.nil?

      true
    end

    def bin_tipped?
      rmt_bin = find_rmt_bin
      return true if !rmt_bin.nil? && !rmt_bin[:bin_tipped_date_time].nil?

      false
    end

    def bin_scrapped?
      rmt_bin = find_rmt_bin
      return true if rmt_bin[:scrapped]

      false
    end
  end
end
