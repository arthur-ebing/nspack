# frozen_string_literal: true

module MesscadaApp
  class TipBin < BaseService
    include BinTipSupport

    attr_reader :repo, :bin_number, :device, :run_id, :rmt_bin_id, :run_attrs

    def initialize(params)
      @repo = MesscadaRepo.new
      @bin_number = params[:bin_number]
      @device = params[:device]
    end

    def call # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      if !bin_exists? && AppConst::CR_RMT.convert_carton_to_rebins? && repo.can_pallet_become_rebin?(bin_number)
        res = convert_carton_to_rebin
        return res unless res.success
      end

      res = CanTipBin.call(bin_number, device)
      return res unless res.success

      res = find_run_and_bin
      return res unless res.success

      location_to_id = ProductionApp::ResourceRepo.new.find_plant_resource(@run_attrs[:packhouse_resource_id]).location_id
      res = FinishedGoodsApp::MoveStock.call(AppConst::BIN_STOCK_TYPE, rmt_bin_id, location_to_id, AppConst::BIN_TIP_MOVE_BIN_BUSINESS_PROCESS, nil)
      return res unless res.success

      update_bin

      run_stats_bins_tipped = repo.get_run_bins_tipped(@run_id)
      success_response('RMT Bin tipped successfully', @run_attrs.merge(rmt_bin_id: @rmt_bin_id, run_id: @run_id, bins_tipped: run_stats_bins_tipped))
    end

    private

    def find_run_and_bin
      run_res = active_run_for_device
      return run_res unless run_res.success

      @run_id = run_res.instance
      @run_attrs = repo.get_run_setup_reqs(@run_id)
      bin = find_rmt_bin
      return failed_response("Bin #{bin_number} not found") if bin.nil?

      @rmt_bin_id = bin[:id]

      ok_response
    end

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
                rmt_container_type_id: repo.get_value(:rmt_container_types, :id, container_type_code: AppConst::DEFAULT_RMT_CONTAINER_TYPE),
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
      updates = { bin_tipped_date_time: Time.now,
                  production_run_tipped_id: @run_id,
                  tipped_asset_number: bin_number,
                  bin_asset_number: nil,
                  exit_ref_date_time: Time.now,
                  bin_tipped: true,
                  exit_ref: 'TIPPED'  }
      RawMaterialsApp::RmtDeliveryRepo.new.update_rmt_bin(@rmt_bin_id, updates)
    end

    def find_rmt_bin
      @find_rmt_bin ||= RawMaterialsApp::RmtDeliveryRepo.new.find_bin_by_asset_number(bin_number)
    end

    def bin_exists?
      !find_rmt_bin.nil?
    end
  end
end
