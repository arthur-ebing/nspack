# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MesscadaApp
  class TestCanTipBin < MiniTestWithHooks
    include Crossbeams::Responses
    include CartonFactory
    include PalletFactory
    include ProductionApp::ProductionRunFactory
    include ProductionApp::ResourceFactory
    include ProductionApp::ProductSetupFactory
    include MasterfilesApp::FarmFactory
    include MasterfilesApp::FruitFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::CalendarFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::TargetMarketFactory
    include MasterfilesApp::GeneralFactory
    include MasterfilesApp::MarketingFactory
    include MasterfilesApp::PackagingFactory
    include MasterfilesApp::HRFactory
    include MasterfilesApp::LocationFactory
    include MasterfilesApp::DepotFactory
    include MasterfilesApp::VesselFactory
    include MasterfilesApp::PortFactory
    include MasterfilesApp::QualityFactory
    include MasterfilesApp::RmtContainerFactory
    include RawMaterialsApp::RmtBinFactory
    include RawMaterialsApp::RmtDeliveryFactory
    include FinishedGoodsApp::LoadFactory
    include FinishedGoodsApp::VoyageFactory
    include QualityApp::MrlResultFactory

    def bintip_criteria(opts = {})
      crit = {}
      %w[
        rmt_code
        rmt_size
        farm_code
        season_code
        commodity_code
        rmt_variety_code
        colour_percentage
        product_class_code
        actual_cold_treatment
        actual_ripeness_treatment
      ].each { |c| crit[c] = opts[c.to_sym] ? 't' : 'f' }
      crit
    end

    def run_data(opts = {})
      data = {
        'cold_store_type' => 'CA',
        'pc_code' => 'CA SMRTFRSH',
        'product_class_code' => '1L',
        'ripe_point_code' => '2CS',
        'rmt_product_type' => 'presort',
        'rmt_size' => '198',
        'track_indicator_code' => 'GDL',
        'treatment_code' => 'Y'
      }
      opts.each { |k, v| data[k.to_s] = v }
      data
    end

    def bin_legacy_data
      {
        'code_cumul' => 'M',
        'cold_store_type' => 'CA',
        'colour' => 'Y',
        'numero_lot_max' => 108_799,
        'pc_name' => 'CA SMRTFRSH',
        'ripe_point_code' => '2CS',
        'track_slms_indicator_1_code' => 'GDL'
      }
    end

    def test_standard_failures
      AppConst::TEST_SETTINGS.client_code = 'hl'
      refute AppConst::CR_PROD.kromco_rmt_integration?

      # 1. bin does not exist
      run_id = create_production_run
      run_res = success_response('ok', run_id)
      CanTipBin.any_instance.stubs(:active_run_for_device).returns(run_res)
      res = MesscadaApp::CanTipBin.call('11', 'CLM-01')
      refute res.success, "Should have failed with bin not found - #{res.message}"

      # 2. bin has been tipped
      bin_id = create_rmt_bin(bin_asset_number: nil,
                              tipped_asset_number: '123456',
                              exit_ref: nil,
                              bin_tipped_date_time: Time.now,
                              scrapped: false)
      bin = DB[:rmt_bins].where(id: bin_id).first
      res = MesscadaApp::CanTipBin.call(bin[:tipped_asset_number], 'CLM-01')
      refute res.success, "Should have failed with bin already tipped - #{res.message}"

      # 3. bin has been scrapped
      DB[:rmt_bins].where(id: bin_id).update(bin_asset_number: '123456', tipped_asset_number: nil, scrapped: true)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      refute res.success, "Should have failed with scrapped bin - #{res.message}"
    ensure
      AppConst::TEST_SETTINGS.client_code = AppConst::TEST_SETTINGS.boot_client_code
    end

    def test_farm
      AppConst::TEST_SETTINGS.client_code = 'hl'

      bin_id = create_rmt_bin(bin_asset_number: '123456',
                              tipped_asset_number: nil,
                              exit_ref: nil,
                              bin_tipped_date_time: nil,
                              scrapped: false,
                              legacy_data: BaseRepo.new.hash_for_jsonb_col(bin_legacy_data))
      run_id = create_production_run(legacy_bintip_criteria: BaseRepo.new.hash_for_jsonb_col(bintip_criteria),
                                     legacy_data: BaseRepo.new.hash_for_jsonb_col(run_data))
      bin = DB[:rmt_bins].where(id: bin_id).first
      run_res = success_response('ok', run_id)
      CanTipBin.any_instance.stubs(:active_run_for_device).returns(run_res)

      # 1. farm ids match
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      assert res.success, "Farm ids should match - #{res.message}"

      refute AppConst::CR_PROD.bintip_allow_farms_of_same_group_to_match?

      # 2. farm ids differ & not allow groups
      farm_id = create_farm(force_create: true)
      DB[:rmt_bins].where(id: bin_id).update(rmt_class_id: create_rmt_class(rmt_class_code: '1L'), farm_id: farm_id)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      refute res.success, "Farm ids should not match and farm groups not checked - #{res.message}"

      AppConst::TEST_SETTINGS.client_code = 'kr' # Allows missmatched farms if farm groups match...
      assert AppConst::CR_PROD.bintip_allow_farms_of_same_group_to_match?
      create_mrl_result(cultivar_id: bin[:cultivar_id],
                        puc_id: bin[:puc_id],
                        season_id: bin[:season_id],
                        rmt_delivery_id: bin[:rmt_delivery_id],
                        farm_id: bin[:farm_id],
                        orchard_id: bin[:orchard_id])

      # 3. farm ids differ & allow groups & groups match
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      assert res.success, "Farm ids do not match, but farm groups should match - #{res.message}"

      # 4. farm ids differ & allow groups & groups do not match
      DB[:farms].where(id: farm_id).update(farm_group_id: create_farm_group(force_create: true))
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      refute res.success, "Farm ids do not match, and farm groups do not match, should fail - #{res.message}"
    ensure
      AppConst::TEST_SETTINGS.client_code = AppConst::TEST_SETTINGS.boot_client_code
    end

    def test_orchard
      AppConst::TEST_SETTINGS.client_code = 'hl'
      bin_id = create_rmt_bin(bin_asset_number: '123456',
                              tipped_asset_number: nil,
                              exit_ref: nil,
                              bin_tipped_date_time: nil,
                              scrapped: false,
                              legacy_data: BaseRepo.new.hash_for_jsonb_col(bin_legacy_data))
      run_id = create_production_run(legacy_bintip_criteria: BaseRepo.new.hash_for_jsonb_col(bintip_criteria),
                                     allow_orchard_mixing: false,
                                     legacy_data: BaseRepo.new.hash_for_jsonb_col(run_data))
      bin = DB[:rmt_bins].where(id: bin_id).first
      run_res = success_response('ok', run_id)
      CanTipBin.any_instance.stubs(:active_run_for_device).returns(run_res)

      # 1. Orchard ids match
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      assert res.success, "Orchard ids should match - #{res.message}"

      # 2. Orchard ids do not match
      orchard_id = create_orchard(force_create: true)
      DB[:rmt_bins].where(id: bin_id).update(orchard_id: orchard_id)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      refute res.success, "Orchard ids should not match - #{res.message}"

      # 3. Orchard ids do not match, but mixing is allowed
      DB[:production_runs].where(id: run_id).update(allow_orchard_mixing: true)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      assert res.success, "Orchard ids do not match, but mixing is allowed - #{res.message}"
    ensure
      AppConst::TEST_SETTINGS.client_code = AppConst::TEST_SETTINGS.boot_client_code
    end

    def test_cultivar_group
      AppConst::TEST_SETTINGS.client_code = 'hl'
      bin_id = create_rmt_bin(bin_asset_number: '123456',
                              tipped_asset_number: nil,
                              exit_ref: nil,
                              bin_tipped_date_time: nil,
                              scrapped: false,
                              legacy_data: BaseRepo.new.hash_for_jsonb_col(bin_legacy_data))
      run_id = create_production_run(legacy_bintip_criteria: BaseRepo.new.hash_for_jsonb_col(bintip_criteria),
                                     allow_cultivar_mixing: true,
                                     allow_cultivar_group_mixing: false,
                                     legacy_data: BaseRepo.new.hash_for_jsonb_col(run_data))
      bin = DB[:rmt_bins].where(id: bin_id).first
      run_res = success_response('ok', run_id)
      CanTipBin.any_instance.stubs(:active_run_for_device).returns(run_res)

      # 1. cultivar_group ids match
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      assert res.success, "cultivar_group ids should match - #{res.message}"

      # 2. cultivar_group ids do not match
      cultivar_group_id = create_cultivar_group(force_create: true)
      cultivar_id = create_cultivar(force_create: true, cultivar_group_id: cultivar_group_id)
      DB[:rmt_bins].where(id: bin_id).update(cultivar_id: cultivar_id, cultivar_group_id: cultivar_group_id)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      refute res.success, "cultivar_group ids should not match - #{res.message}"

      # 3. cultivar_group ids do not match, but mixing is allowed
      DB[:production_runs].where(id: run_id).update(allow_cultivar_group_mixing: true)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      assert res.success, "cultivar_group ids do not match, but mixing is allowed - #{res.message}"
    ensure
      AppConst::TEST_SETTINGS.client_code = AppConst::TEST_SETTINGS.boot_client_code
    end

    def test_cultivar
      AppConst::TEST_SETTINGS.client_code = 'hl'
      bin_id = create_rmt_bin(bin_asset_number: '123456',
                              tipped_asset_number: nil,
                              exit_ref: nil,
                              bin_tipped_date_time: nil,
                              scrapped: false,
                              legacy_data: BaseRepo.new.hash_for_jsonb_col(bin_legacy_data))
      run_id = create_production_run(legacy_bintip_criteria: BaseRepo.new.hash_for_jsonb_col(bintip_criteria),
                                     allow_cultivar_mixing: false,
                                     legacy_data: BaseRepo.new.hash_for_jsonb_col(run_data))
      bin = DB[:rmt_bins].where(id: bin_id).first
      run_res = success_response('ok', run_id)
      CanTipBin.any_instance.stubs(:active_run_for_device).returns(run_res)

      # 1. Cultivar ids match
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      assert res.success, "Cultivar ids should match - #{res.message}"

      # 2. Cultivar ids do not match
      cultivar_id = create_cultivar(force_create: true)
      DB[:rmt_bins].where(id: bin_id).update(cultivar_id: cultivar_id)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      refute res.success, "Cultivar ids should not match - #{res.message}"

      # 3. Cultivar ids do not match, but mixing is allowed
      DB[:production_runs].where(id: run_id).update(allow_cultivar_mixing: true)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      assert res.success, "Cultivar ids do not match, but mixing is allowed - #{res.message}"
    ensure
      AppConst::TEST_SETTINGS.client_code = AppConst::TEST_SETTINGS.boot_client_code
    end

    def test_standard_check_pass
      AppConst::TEST_SETTINGS.client_code = 'hl'
      bin_id = create_rmt_bin(bin_asset_number: '123456',
                              tipped_asset_number: nil,
                              exit_ref: nil,
                              bin_tipped_date_time: nil,
                              scrapped: false,
                              legacy_data: BaseRepo.new.hash_for_jsonb_col(bin_legacy_data))
      run_id = create_production_run(legacy_bintip_criteria: BaseRepo.new.hash_for_jsonb_col(bintip_criteria(cold_store_type: true,
                                                                                                             commodity_code: true,
                                                                                                             farm_code: true,
                                                                                                             pc_code: true,
                                                                                                             product_class_code: true,
                                                                                                             ripe_point_code: true,
                                                                                                             rmt_product_type: true,
                                                                                                             rmt_size: true,
                                                                                                             rmt_variety_code: true,
                                                                                                             season_code: true,
                                                                                                             track_indicator_code: true,
                                                                                                             treatment_code: true)),
                                     legacy_data: BaseRepo.new.hash_for_jsonb_col({}))
      bin = DB[:rmt_bins].where(id: bin_id).first
      run_res = success_response('ok', run_id)
      CanTipBin.any_instance.stubs(:active_run_for_device).returns(run_res)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      assert res.success, "Should be able to tip the bin regardless of bintip criteria - #{res.message}"
    ensure
      AppConst::TEST_SETTINGS.client_code = AppConst::TEST_SETTINGS.boot_client_code
    end

    def test_kr_check_pass
      AppConst::TEST_SETTINGS.client_code = 'kr'
      assert AppConst::CR_PROD.kromco_rmt_integration?

      cp_id = create_colour_percentage(colour_percentage: '20-50')
      cp_id2 = create_colour_percentage(colour_percentage: 'G')
      size_id = create_rmt_size(size_code: '198')
      size_id2 = create_rmt_size(size_code: 'SMALL')
      class_id = create_rmt_class(rmt_class_code: '1L')
      class_id2 = create_rmt_class(rmt_class_code: 'CII')
      rmt_code_id = create_rmt_code(rmt_code: 'ARB')
      rmt_code_id2 = create_rmt_code(rmt_code: 'GDG')
      season_id = create_season(season_code: '2021_AP')
      season_id2 = create_season(season_code: '2020_AP')
      actual_cold_treatment_id = create_treatment(treatment_code: 'SMARTFRESH')
      actual_cold_treatment_id2 = create_treatment(treatment_code: 'CA')
      actual_ripeness_treatment_id = create_treatment(treatment_code: 'RA')
      actual_ripeness_treatment_id2 = create_treatment(treatment_code: 'DA')
      bin_id = create_rmt_bin(bin_asset_number: '123456',
                              tipped_asset_number: nil,
                              exit_ref: nil,
                              bin_tipped_date_time: nil,
                              rmt_class_id: class_id,
                              rmt_size_id: size_id,
                              rmt_code_id: rmt_code_id,
                              season_id: season_id,
                              colour_percentage_id: cp_id,
                              actual_cold_treatment_id: actual_cold_treatment_id,
                              actual_ripeness_treatment_id: actual_ripeness_treatment_id,
                              scrapped: false,
                              legacy_data: BaseRepo.new.hash_for_jsonb_col(bin_legacy_data))

      # 1. All criteria false
      run_id = create_production_run(legacy_bintip_criteria: BaseRepo.new.hash_for_jsonb_col(bintip_criteria))
      bin = DB[:rmt_bins].where(id: bin_id).first
      run_res = success_response('ok', run_id)
      create_mrl_result(cultivar_id: bin[:cultivar_id],
                        puc_id: bin[:puc_id],
                        season_id: bin[:season_id],
                        rmt_delivery_id: bin[:rmt_delivery_id],
                        farm_id: bin[:farm_id],
                        orchard_id: bin[:orchard_id])

      CanTipBin.any_instance.stubs(:active_run_for_device).returns(run_res)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      assert res.success, "Should be able to tip the bin - #{res.message}"

      # 2. colour percentage
      DB[:production_runs].where(id: run_id).update(legacy_bintip_criteria: BaseRepo.new.hash_for_jsonb_col(bintip_criteria(colour_percentage: true)),
                                                    colour_percentage_id: cp_id2)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      refute res.success, "Should not be able to tip based on colour percentage - #{res.message}"

      DB[:production_runs].where(id: run_id).update(colour_percentage_id: cp_id)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      assert res.success, "Should be able to tip based on matching colour percentage - #{res.message}"

      # 3. rmt size
      DB[:production_runs].where(id: run_id).update(legacy_bintip_criteria: BaseRepo.new.hash_for_jsonb_col(bintip_criteria(rmt_size: true)),
                                                    rmt_size_id: size_id2)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      refute res.success, "Should not be able to tip based on rmt size - #{res.message}"

      DB[:production_runs].where(id: run_id).update(rmt_size_id: size_id)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      assert res.success, "Should be able to tip based on matching rmt size - #{res.message}"

      # 4. product class code
      DB[:production_runs].where(id: run_id).update(legacy_bintip_criteria: BaseRepo.new.hash_for_jsonb_col(bintip_criteria(product_class_code: true)),
                                                    rmt_class_id: class_id2)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      refute res.success, "Should not be able to tip based on class code - #{res.message}"

      DB[:production_runs].where(id: run_id).update(rmt_class_id: class_id)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      assert res.success, "Should be able to tip based on matching class code - #{res.message}"

      # 5. rmt code
      DB[:production_runs].where(id: run_id).update(legacy_bintip_criteria: BaseRepo.new.hash_for_jsonb_col(bintip_criteria(rmt_code: true)),
                                                    rmt_code_id: rmt_code_id2)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      refute res.success, "Should not be able to tip based on rmt code - #{res.message}"

      DB[:production_runs].where(id: run_id).update(rmt_code_id: rmt_code_id)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      assert res.success, "Should be able to tip based on matching rmt code - #{res.message}"

      # 6. season code
      DB[:production_runs].where(id: run_id).update(legacy_bintip_criteria: BaseRepo.new.hash_for_jsonb_col(bintip_criteria(season_code: true)),
                                                    season_id: season_id2)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      refute res.success, "Should not be able to tip based on season code - #{res.message}"

      DB[:production_runs].where(id: run_id).update(season_id: season_id)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      assert res.success, "Should be able to tip based on matching season code - #{res.message}"

      # 7. actual cold treatment
      DB[:production_runs].where(id: run_id).update(legacy_bintip_criteria: BaseRepo.new.hash_for_jsonb_col(bintip_criteria(actual_cold_treatment: true)),
                                                    actual_cold_treatment_id: actual_cold_treatment_id2)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      refute res.success, "Should not be able to tip based on actual cold treatment - #{res.message}"

      DB[:production_runs].where(id: run_id).update(actual_cold_treatment_id: actual_cold_treatment_id)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      assert res.success, "Should be able to tip based on matching actual cold treatment - #{res.message}"

      # 8. actual ripeness treatment
      DB[:production_runs].where(id: run_id).update(legacy_bintip_criteria: BaseRepo.new.hash_for_jsonb_col(bintip_criteria(actual_ripeness_treatment: true)),
                                                    actual_ripeness_treatment_id: actual_ripeness_treatment_id2)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      refute res.success, "Should not be able to tip based on actual ripeness treatment - #{res.message}"

      DB[:production_runs].where(id: run_id).update(actual_ripeness_treatment_id: actual_ripeness_treatment_id)
      res = MesscadaApp::CanTipBin.call(bin[:bin_asset_number], 'CLM-01')
      assert res.success, "Should be able to tip based on matching actual ripeness treatment - #{res.message}"
    ensure
      AppConst::TEST_SETTINGS.client_code = AppConst::TEST_SETTINGS.boot_client_code
    end
  end
end
