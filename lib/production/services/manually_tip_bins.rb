# frozen_string_literal: true

module ProductionApp
  class ManuallyTipBins < BaseService
    attr_reader :repo, :messcada_repo, :rmt_bin_numbers, :production_run_id, :bin_number, :rmt_bin_id, :run_attrs, :bin_attrs

    def initialize(params)
      @repo = ProductionApp::ReworksRepo.new
      @messcada_repo = MesscadaApp::MesscadaRepo.new
      @rmt_bin_numbers = params[:pallets_selected]
      @production_run_id = params[:production_run_id]
      @run_attrs = messcada_repo.get_run_setup_reqs(production_run_id)
    end

    def call
      res = manually_tip_bins
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      ok_response
    end

    private

    def manually_tip_bins  # rubocop:disable Metrics/AbcSize
      rmt_bin_numbers.each  do |rmt_bin_number|
        @bin_number = rmt_bin_number
        @rmt_bin_id = find_rmt_bin

        @bin_attrs = messcada_repo.get_rmt_bin_setup_reqs(rmt_bin_id)
        errors = rmt_bin_validations
        return failed_response(errors) unless errors.nil?

        res = move_bin
        return res unless res.success

        res = update_bin
        return res unless res.success
      end

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def find_rmt_bin
      # return repo.rmt_bin_from_asset_number(bin_number) if AppConst::USE_PERMANENT_RMT_BIN_BARCODES

      repo.find_rmt_bin(bin_number.to_i)
    end

    def rmt_bin_validations
      return "Bin:#{bin_number} could not be found" unless bin_exists?
      return "Bin:#{bin_number} has already been tipped" unless bin_tipped?.nil_or_empty?

      setup_errors = validate_setup_requirements
      return setup_errors unless setup_errors.nil?
    end

    def bin_exists?
      repo.rmt_bins_exists?(bin_number)
    end

    def bin_tipped?
      repo.tipped_bins?(bin_number)
    end

    def validate_setup_requirements # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      return "INVALID FARM: Run requires: #{run_attrs[:farm_code]}. Bin is: #{bin_attrs[:farm_code]}" unless bin_attrs[:farm_id] == run_attrs[:farm_id]
      return "INVALID ORCHARD: Run requires: #{run_attrs[:orchard_code]}. Bin is: #{bin_attrs[:orchard_code]}" if !run_attrs[:allow_orchard_mixing] && (bin_attrs[:orchard_id] != run_attrs[:orchard_id])
      return "INVALID CULTIVAR GROUP: Run requires: #{run_attrs[:cultivar_group_code]}. Bin is: #{bin_attrs[:cultivar_group_code]}" unless bin_attrs[:cultivar_group_id] == run_attrs[:cultivar_group_id]
      return "INVALID CULTIVAR: Run requires: #{run_attrs[:cultivar_name]}. Bin is: #{bin_attrs[:cultivar_name]}" if !run_attrs[:allow_cultivar_mixing] && (bin_attrs[:cultivar_id] != run_attrs[:cultivar_id])
    end

    def move_bin
      location_id = repo.find_run_location_id(production_run_id)
      return failed_response('Location does not exist') if location_id.nil_or_empty?

      res = FinishedGoodsApp::MoveStockService.new(AppConst::BIN_STOCK_TYPE, bin_number, location_id, AppConst::REWORKS_MOVE_BIN_BUSINESS_PROCESS, nil).call
      return res unless res.success

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_bin
      RawMaterialsApp::RmtDeliveryRepo.new.update_rmt_bin(rmt_bin_id, rmt_bin_updates)

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def rmt_bin_updates
      defaults = { bin_tipped_date_time: Time.now,
                   production_run_tipped_id: production_run_id,
                   exit_ref_date_time: Time.now,
                   bin_tipped: true,
                   exit_ref: 'TIPPED',
                   tipped_manually: true }
      defaults = defaults.merge!(rmt_bin_asset_number_updates) if AppConst::USE_PERMANENT_RMT_BIN_BARCODES
      defaults
    end

    def rmt_bin_asset_number_updates
      { tipped_asset_number: rmt_bin_asset_number,
        bin_asset_number: nil }
    end

    def rmt_bin_asset_number
      repo.get_rmt_bin_asset_number(bin_number)
    end
  end
end
