# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPalletBasePermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        pallet_base_code: Faker::Lorem.unique.word,
        description: 'ABC',
        length: 1,
        width: 1,
        edi_in_pallet_base: 'ABC',
        edi_out_pallet_base: 'ABC',
        cartons_per_layer: 1,
        material_mass: 1.0,
        active: true
      }
      MasterfilesApp::PalletBase.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::PalletBase.call(:create)
      assert res.success, 'Should always be able to create a pallet_base'
    end

    def test_edit
      MasterfilesApp::PackagingRepo.any_instance.stubs(:find_pallet_base).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PalletBase.call(:edit, 1)
      assert res.success, 'Should be able to edit a pallet_base'
    end

    def test_delete
      MasterfilesApp::PackagingRepo.any_instance.stubs(:find_pallet_base).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PalletBase.call(:delete, 1)
      assert res.success, 'Should be able to delete a pallet_base'
    end
  end
end
