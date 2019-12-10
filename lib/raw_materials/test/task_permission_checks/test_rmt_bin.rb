# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module RawMaterialsApp
  class TestRmtBinPermission < Minitest::Test
    include Crossbeams::Responses
    # include RmtBinFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        rmt_delivery_id: 1, # rmt_delivery_id,
        season_id: 1, # season_id,
        cultivar_id: 1, # cultivar_id,
        orchard_id: 1, # orchard_id,
        farm_id: 1, # farm_id,
        rmt_class_id: 1, # rmt_class_id,
        rmt_material_owner_party_role_id: 1, # rmt_material_owner_party_role_id,
        rmt_container_type_id: 1, # rmt_container_type_id,
        rmt_container_material_type_id: 1, # rmt_container_material_type_id,
        cultivar_group_id: 1, # cultivar_group_id,
        puc_id: 1, # puc_id,
        status: Faker::Lorem.unique.word,
        exit_ref: 'ABC',
        qty_bins: 1,
        bin_asset_number: 'A1',
        tipped_asset_number: 'A1',
        rmt_inner_container_type_id: 1,
        rmt_inner_container_material_id: 1,
        qty_inner_bins: 1,
        production_run_rebin_id: 1,
        production_run_tipped_id: 1,
        bin_tipping_plant_resource_id: 1,
        bin_fullness: 1.0,
        nett_weight: 1.0,
        gross_weight: 1.0,
        bin_tipped: false,
        bin_received_date_time: '2010-01-01 12:00',
        bin_tipped_date_time: '2010-01-01 12:00',
        exit_ref_date_time: '2010-01-01 12:00',
        rebin_created_at: '2010-01-01 12:00',
        active: true,
        scrapped: false,
        scrapped_at: '2010-01-01 12:00'
      }
      RawMaterialsApp::RmtBin.new(base_attrs.merge(attrs))
    end

    def test_create
      res = RawMaterialsApp::TaskPermissionCheck::RmtBin.call(:create)
      assert res.success, 'Should always be able to create a rmt_bin'
    end

    def test_edit
      RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_bin).returns(entity)
      res = RawMaterialsApp::TaskPermissionCheck::RmtBin.call(:edit, 1)
      assert res.success, 'Should be able to edit a rmt_bin'

      # RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_bin).returns(entity(completed: true))
      # res = RawMaterialsApp::TaskPermissionCheck::RmtBin.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed rmt_bin'
    end

    def test_delete
      RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_bin).returns(entity)
      res = RawMaterialsApp::TaskPermissionCheck::RmtBin.call(:delete, 1)
      assert res.success, 'Should be able to delete a rmt_bin'

      # RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_bin).returns(entity(completed: true))
      # res = RawMaterialsApp::TaskPermissionCheck::RmtBin.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed rmt_bin'
    end

    # def test_complete
    #   RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_bin).returns(entity)
    #   res = RawMaterialsApp::TaskPermissionCheck::RmtBin.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a rmt_bin'

    #   RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_bin).returns(entity(completed: true))
    #   res = RawMaterialsApp::TaskPermissionCheck::RmtBin.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed rmt_bin'
    # end

    # def test_approve
    #   RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_bin).returns(entity(completed: true, approved: false))
    #   res = RawMaterialsApp::TaskPermissionCheck::RmtBin.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed rmt_bin'

    #   RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_bin).returns(entity)
    #   res = RawMaterialsApp::TaskPermissionCheck::RmtBin.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed rmt_bin'

    #   RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_bin).returns(entity(completed: true, approved: true))
    #   res = RawMaterialsApp::TaskPermissionCheck::RmtBin.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved rmt_bin'
    # end

    # def test_reopen
    #   RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_bin).returns(entity)
    #   res = RawMaterialsApp::TaskPermissionCheck::RmtBin.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a rmt_bin that has not been approved'

    #   RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:find_rmt_bin).returns(entity(completed: true, approved: true))
    #   res = RawMaterialsApp::TaskPermissionCheck::RmtBin.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved rmt_bin'
    # end
  end
end
