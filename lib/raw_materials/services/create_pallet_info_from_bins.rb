module RawMaterialsApp
  class CreatePalletInfoFromBins < BaseService
    attr_accessor :repo, :user_name, :rep_bin, :pallet_format_id, :bins

    def initialize(user_name, pallet_format_id, bins_info)
      @repo = RawMaterialsApp::RmtDeliveryRepo.new
      @messcada_repo = MesscadaApp::MesscadaRepo.new
      @prod_setup_repo = ProductionApp::ProductSetupRepo.new
      @user_name = user_name
      @pallet_format_id = pallet_format_id
      @rep_bin = @repo.where(:rmt_bins, RawMaterialsApp::RmtBin, bin_asset_number: bins_info[0][:bin_asset_number])
      @bins = bins_info
    end

    def call
      plt_res = validate_pallet_attrs
      return plt_res unless plt_res.success

      seqs_res = validate_pallet_sequences_attrs
      return seqs_res unless seqs_res.success

      repo.transaction do
        res = create_pallet_and_sequences(plt_res.instance, seqs_res.instance)

        success_response('ok', res)
      end
    end

    def validate_pallet_attrs # rubocop:disable Metrics/AbcSize
      @palletized_at = Time.now
      production_line_resource = ProductionApp::ResourceRepo.new.find_plant_resource(bins[0][:production_line_id])
      production_line_packhouse_resource = repo.get_line_packhouse_resource(production_line_resource.id)
      pallet_attrs = { location_id: production_line_packhouse_resource[:location_id], shipped: false, in_stock: true, inspected: false,
                       stock_created_at: rep_bin.created_at, phc: production_line_resource.resource_properties ? production_line_resource.resource_properties['phc'] : nil,
                       gross_weight: repo.select_values(:rmt_bins, :gross_weight, bin_asset_number: bins.map { |b| b[:bin_asset_number] }).sum,
                       partially_palletized: false, palletized_at: @palletized_at, allocated: false, reinspected: false, scrapped: false, pallet_format_id: pallet_format_id,
                       plt_line_resource_id: production_line_resource.id, plt_packhouse_resource_id: production_line_packhouse_resource[:id], re_calculate_nett_weight: false, repacked: false, has_individual_cartons: false,
                       nett_weight_externally_calculated: true }

      res = validate_pallet_params(pallet_attrs)
      return validation_failed_response(res) if res.failure?

      success_response('ok', res.to_h)
    end

    def validate_pallet_sequences_attrs # rubocop:disable Metrics/AbcSize
      instances = []
      bins.size.times do |i| # rubocop:disable Metrics/BlockLength
        production_line_packhouse_resource = repo.get_line_packhouse_resource(bins[i][:production_line_id])
        bin_info = bins[i]
        bin = repo.where(:rmt_bins, RawMaterialsApp::RmtBin, bin_asset_number: bin_info[:bin_asset_number])
        puc_id = bin.puc_id || repo.get_value(:production_runs, :puc_id, id: bin.production_run_rebin_id)
        orchard_id = bin.orchard_id || repo.get_value(:production_runs, :orchard_id, id: bin.production_run_rebin_id)
        attrs = { pallet_sequence_number: i + 1,
                  production_run_id: bin.production_run_rebin_id,
                  farm_id: bin.farm_id || repo.get_value(:production_runs, :farm_id, id: bin.production_run_rebin_id),
                  puc_id: puc_id,
                  orchard_id: orchard_id,
                  marketing_puc_id: puc_id,
                  marketing_orchard_id: repo.registered_orchard_by_puc_orchard_and_cultivar(puc_id, orchard_id, bin.cultivar_id),
                  cultivar_id: bin.cultivar_id,
                  cultivar_group_id: repo.get_value(:cultivars, :cultivar_group_id, id: bin.cultivar_id),
                  basic_pack_code_id: bin_info[:basic_pack_code_id],
                  packhouse_resource_id: production_line_packhouse_resource[:id],
                  production_line_id: bins[i][:production_line_id],
                  season_id: bin.season_id,
                  marketing_variety_id: bin_info[:marketing_variety_id],
                  standard_pack_code_id: @prod_setup_repo.basic_pack_standard_pack_code_id(bin_info[:basic_pack_code_id]),
                  fruit_size_reference_id: bin_info[:fruit_size_ref_id],
                  marketing_org_party_role_id: bin_info[:marketing_party_role_id],
                  packed_tm_group_id: bin_info[:packed_tm_group_id],
                  mark_id: bin_info[:mark_id],
                  inventory_code_id: bin_info[:inventory_code_id],
                  pallet_format_id: pallet_format_id,
                  cartons_per_pallet_id: repo.get_value(:cartons_per_pallet, :id, pallet_format_id: pallet_format_id, basic_pack_id: bin_info[:basic_pack_code_id]),
                  carton_quantity: 1,
                  verification_result: 'PASSED',
                  verified_at: @palletized_at,
                  nett_weight: bin.nett_weight,
                  verified: true,
                  verification_passed: true,
                  grade_id: bin_info[:grade_id],
                  sell_by_code: bin_info[:sell_by_code],
                  rmt_class_id: bin.rmt_class_id,
                  source_bin_id: bin.id }
        gtin_code = @prod_setup_repo.find_gtin_code_for_update(attrs) if @prod_setup_repo.recalc_gtin_code?(attrs)
        attrs.store(:gtin_code, gtin_code)
        res = validate_pallet_sequence_params(attrs)
        return validation_failed_response(res) if res.failure?

        instances << res.to_h
      end

      success_response('ok', instances)
    end

    def create_pallet_and_sequences(pallet, sequences) # rubocop:disable Metrics/AbcSize
      pallet_id = @messcada_repo.create_pallet(user_name, pallet)
      repo.log_status('pallets', pallet_id, AppConst::CREATED_FROM_BIN)

      seq_ids = []
      sequences.each do |s|
        seq_ids << @messcada_repo.create_sequences(s, pallet_id)
      end
      repo.log_multiple_statuses(:pallet_sequences, seq_ids, AppConst::CREATED_FROM_BIN)
      bin_ids = repo.select_values(:rmt_bins, :id, bin_asset_number: bins.map { |b| b[:bin_asset_number] })
      repo.log_multiple_statuses(:rmt_bins, bin_ids, AppConst::CONVERTED_TO_PALLET)

      { pallet_id: pallet_id, pallet_sequence_ids: seq_ids }
    end

    def validate_pallet_sequence_params(params)
      MesscadaApp::BinToPalletSequenceSchema.call(params)
    end

    def validate_pallet_params(params)
      MesscadaApp::BinToPalletSchema.call(params)
    end
  end
end
