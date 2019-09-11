# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module RawMaterialsApp
  class TestRmtBinInteractor < MiniTestWithHooks
    include RmtBinFactory
    include MasterfilesApp::PartyFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(RawMaterialsApp::RmtDeliveryRepo)
    end

    def test_rmt_bin
      RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_bin).returns(fake_rmt_bin)
      entity = interactor.send(:rmt_bin, 1)
      assert entity.is_a?(RmtBin)
    end

    def test_create_rmt_bin
      delivery_id = create_rmt_delivery
      attrs = fake_rmt_bin.to_h.reject { |k, _| k == :id }
      res = interactor.create_rmt_bin(delivery_id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(RmtBin, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_rmt_bin_fail
      rmt_delivery_id = create_rmt_delivery
      attrs = fake_rmt_bin(rmt_container_type_id: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_rmt_bin(rmt_delivery_id, attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:rmt_container_type_id]
    end

    def test_update_rmt_bin
      id = create_rmt_bin
      attrs = interactor.send(:repo).find_hash(:rmt_bins, id).reject { |k, _| k == :id }
      value = attrs[:qty_bins]
      attrs[:qty_bins] = 99
      res = interactor.update_rmt_bin(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(RmtBin, res.instance)
      assert_equal 99, res.instance.qty_bins
      refute_equal value, res.instance.qty_bins
    end

    def test_update_rmt_bin_fail
      id = create_rmt_bin
      attrs = interactor.send(:repo).find_hash(:rmt_bins, id).reject { |k, _| %i[id rmt_container_type_id].include?(k) }
      value = attrs[:exit_ref]
      attrs[:exit_ref] = 'a_change'
      res = interactor.update_rmt_bin(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:rmt_container_type_id]
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
      rmt_container_material_owner_id = create_rmt_container_material_owner
      rmt_container_type_id = create_rmt_container_type
      rmt_container_material_type_id = create_rmt_container_material_type
      cultivar_group_id = create_cultivar_group
      puc_id = create_puc

      {
        id: 1,
        rmt_delivery_id: rmt_delivery_id,
        season_id: season_id,
        cultivar_id: cultivar_id,
        orchard_id: orchard_id,
        farm_id: farm_id,
        rmt_class_id: rmt_class_id,
        rmt_container_material_owner_id: rmt_container_material_owner_id,
        rmt_container_type_id: rmt_container_type_id,
        rmt_container_material_type_id: rmt_container_material_type_id,
        cultivar_group_id: cultivar_group_id,
        puc_id: puc_id,
        status: Faker::Lorem.unique.word,
        exit_ref: 'ABC',
        qty_bins: 1,
        bin_asset_number: 1,
        tipped_asset_number: 1,
        rmt_inner_container_type_id: 1,
        rmt_inner_container_material_id: 1,
        qty_inner_bins: 1,
        production_run_rebin_id: 1,
        production_run_tipped_id: 1,
        production_run_tipping_id: 1,
        bin_tipping_plant_resource_id: 1,
        bin_fullness: 'Full',
        nett_weight: 1.0,
        gross_weight: 1.0,
        bin_tipped: false,
        tipping: false,
        bin_received_date_time: '2010-01-01 12:00',
        bin_tipped_date_time: '2010-01-01 12:00',
        exit_ref_date_time: '2010-01-01 12:00',
        bin_tipping_started_date_time: '2010-01-01 12:00',
        rebin_created_at: '2010-01-01 12:00',
        active: true
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
