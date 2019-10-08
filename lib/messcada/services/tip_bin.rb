# frozen_string_literal: true

module MesscadaApp
  class TipBin < BaseService
    attr_reader :repo, :bin_number, :device, :run_id, :rmt_bin_id, :run_attrs

    def initialize(params)
      @repo = MesscadaRepo.new
      @bin_number = params[:bin_number]
      @device = params[:device]
    end

    def call
      errors = validations
      return failed_response(errors) unless errors.nil?

      update_bin

      run_stats_bins_tipped = repo.production_run_stats(@run_id)

      success_response('rmt bin tipped successfully', @run_attrs.merge(rmt_bin_id: @rmt_bin_id, run_id: @run_id, bins_tipped: run_stats_bins_tipped))
    end

    private

    def update_bin
      updates = { bin_tipped_date_time: Time.now, production_run_tipped_id: @run_id, exit_ref_date_time: Time.now, bin_tipped: true, exit_ref: 'TIPPED'  }
      updates.merge!(tipped_asset_number: bin_number, bin_asset_number: nil) unless AppConst::USE_PERMANENT_RMT_BIN_BARCODES != 'true'

      RawMaterialsApp::RmtDeliveryRepo.new.update_rmt_bin(@rmt_bin_id, updates)
    end

    def validations # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      return "Bin:#{bin_number} could not be found" unless bin_exists?
      return "Bin:#{bin_number} has already been tipped" if bin_tipped?

      line = ProductionApp::ResourceRepo.new.plant_resource_parent_of_system_resource(Crossbeams::Config::ResourceDefinitions::LINE, @device)
      return line.message unless line.success

      res = ProductionApp::ProductionRunRepo.new.find_production_runs_for_line_in_state(line.instance, running: true, tipping: true)
      return res.message unless res.success

      return 'More than one tipping run on line' unless res.instance.length == 1

      rmt_bin = find_rmt_bin
      run = ProductionApp::ProductionRunRepo.new.find_production_run(res.instance[0])

      @run_id = run[:id]
      @rmt_bin_id = rmt_bin[:id]
      if (setup_errors = validate_setup_requirements(rmt_bin[:id], run[:id]))
        return setup_errors
      end

      nil
    end

    def validate_setup_requirements(rmt_bin_id, run_id) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      bin_attrs = repo.get_rmt_bin_setup_reqs(rmt_bin_id)
      @run_attrs = repo.get_run_setup_reqs(run_id)
      return "INVALID FARM: Run requires: #{run_attrs[:farm_code]}. Bin is: #{bin_attrs[:farm_code]}" unless bin_attrs[:farm_id] == run_attrs[:farm_id]
      return "INVALID ORCHARD: Run requires: #{run_attrs[:orchard_code]}. Bin is: #{bin_attrs[:orchard_code]}" if !run_attrs[:allow_orchard_mixing] && (bin_attrs[:orchard_id] != run_attrs[:orchard_id])
      return "INVALID CULTIVAR GROUP: Run requires: #{run_attrs[:cultivar_group_code]}. Bin is: #{bin_attrs[:cultivar_group_code]}" unless bin_attrs[:cultivar_group_id] == run_attrs[:cultivar_group_id]
      return "INVALID CULTIVAR: Run requires: #{run_attrs[:cultivar_name]}. Bin is: #{bin_attrs[:cultivar_name]}" if !run_attrs[:allow_cultivar_mixing] && (bin_attrs[:cultivar_id] != run_attrs[:cultivar_id])
    end

    def find_rmt_bin
      return RawMaterialsApp::RmtDeliveryRepo.new.find_bin_by_asset_number(bin_number) if AppConst::USE_PERMANENT_RMT_BIN_BARCODES == 'true'

      RawMaterialsApp::RmtDeliveryRepo.new.find_rmt_bin(bin_number)
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
  end
end
