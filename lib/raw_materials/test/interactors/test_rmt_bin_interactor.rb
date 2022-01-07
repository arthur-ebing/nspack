# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module RawMaterialsApp
  class TestRmtBinInteractor < MiniTestWithHooks
    include RmtBinFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::FarmFactory
    include MasterfilesApp::CalendarFactory
    include MasterfilesApp::RmtContainerFactory
    include MasterfilesApp::LocationFactory
    include RawMaterialsApp::RmtDeliveryFactory
    include ProductionApp::ProductionRunFactory
    include ProductionApp::ResourceFactory
    include ProductionApp::ProductSetupFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(RawMaterialsApp::RmtDeliveryRepo)
    end

    def test_rmt_bin
      RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_bin_flat).returns(fake_rmt_bin)
      entity = interactor.send(:rmt_bin, 1)
      assert entity.is_a?(RmtBin)
    end

    def test_create_rmt_bin
      delivery_id = create_rmt_delivery
      attrs = fake_rmt_bin.to_h.reject { |k, _| k == :id }
      res = AppConst.stub_consts(BIN_ASSET_REGEX: '.+') do
        interactor.create_rmt_bin(delivery_id, attrs)
      end
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(RmtBinFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_rmt_bin_fail
      rmt_delivery_id = create_rmt_delivery
      attrs = fake_rmt_bin(bin_fullness: nil).to_h.reject { |k, _| k == :id }
      res = AppConst.stub_consts(BIN_ASSET_REGEX: '.+') do
        interactor.create_rmt_bin(rmt_delivery_id, attrs)
      end
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:bin_fullness]
    end

    def test_update_rmt_bin
      id = create_rmt_bin
      attrs = interactor.send(:repo).find_hash(:rmt_bins, id).reject { |k, _| k == :id }
      value = attrs[:qty_bins]
      attrs[:qty_bins] = 99
      res = interactor.update_rmt_bin(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(RmtBinFlat, res.instance)
      assert_equal 99, res.instance.qty_bins
      refute_equal value, res.instance.qty_bins
    end

    def test_update_rmt_bin_fail
      id = create_rmt_bin
      attrs = interactor.send(:repo).find_hash(:rmt_bins, id).reject { |k, _| %i[id rmt_container_type_id].include?(k) }
      value = attrs[:exit_ref]
      attrs[:exit_ref] = 'a_change'
      attrs[:bin_fullness] = nil
      res = interactor.update_rmt_bin(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['must be filled'], res.errors[:bin_fullness]
      after = interactor.send(:repo).find_hash(:rmt_bins, id)
      refute_equal 'a_change', after[:exit_ref]
      assert_equal value, after[:exit_ref]
    end

    def test_delete_rmt_bin
      id = create_rmt_bin
      assert_count_changed(:rmt_bins, -1) do
        res = interactor.delete_rmt_bin(id)
        assert res.success, res.message
      end
    end

    private

    def rmt_bin_attrs
      rmt_delivery_id = create_rmt_delivery
      season_id = create_season
      cultivar_id = create_cultivar
      orchard_id = create_orchard
      farm_id = create_farm
      rmt_class_id = create_rmt_class
      rmt_material_owner_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_IMPLEMENTATION_OWNER)
      rmt_container_type_id = create_rmt_container_type
      rmt_container_material_type_id = create_rmt_container_material_type
      cultivar_group_id = create_cultivar_group
      puc_id = create_puc
      location_id = create_location
      rmt_size_id = create_rmt_size

      {
        id: 1,
        rmt_delivery_id: rmt_delivery_id,
        season_id: season_id,
        cultivar_id: cultivar_id,
        orchard_id: orchard_id,
        farm_id: farm_id,
        rmt_class_id: rmt_class_id,
        rmt_material_owner_party_role_id: rmt_material_owner_party_role_id,
        rmt_container_type_id: rmt_container_type_id,
        rmt_container_material_type_id: rmt_container_material_type_id,
        cultivar_group_id: cultivar_group_id,
        location_id: location_id,
        puc_id: puc_id,
        rmt_size_id: rmt_size_id,
        status: Faker::Lorem.unique.word,
        exit_ref: 'ABC',
        qty_bins: 1,
        bin_asset_number: 'A1',
        tipped_asset_number: 'A1',
        rmt_inner_container_type_id: 1,
        rmt_inner_container_material_id: 1,
        colour_percentage_id: 1,
        actual_cold_treatment_id: 1,
        actual_ripeness_treatment_id: 1,
        rmt_code_id: 1,
        qty_inner_bins: 1,
        production_run_rebin_id: 1,
        production_run_tipped_id: 1,
        bin_tipping_plant_resource_id: 1,
        bin_fullness: AppConst::BIN_FULL,
        nett_weight: 1.0,
        gross_weight: 1.0,
        bin_tipped: false,
        bin_received_date_time: '2010-01-01 12:00',
        bin_tipped_date_time: '2010-01-01 12:00',
        exit_ref_date_time: '2010-01-01 12:00',
        rebin_created_at: '2010-01-01 12:00',
        created_at: '2010-01-01 12:00',
        active: true,
        scrapped: false,
        scrapped_at: '2010-01-01 12:00',
        scrapped_rmt_delivery_id: 1,
        legacy_data: {}
      }
    end

    def fake_rmt_bin(overrides = {})
      RmtBin.new(rmt_bin_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= RmtBinInteractor.new(current_user, {}, {}, {})
    end
  end
end
