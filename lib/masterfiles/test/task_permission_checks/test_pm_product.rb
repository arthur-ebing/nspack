# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPmProductPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        pm_subtype_id: 1,
        erp_code: Faker::Lorem.unique.word,
        product_code: 'ABC',
        description: 'ABC',
        active: true,
        subtype_code: 'ABC',
        material_mass: 1.0,
        basic_pack_id: 1,
        height_mm: 1,
        basic_pack_code: 'ABC',
        pm_type_code: 'ABC'
      }
      MasterfilesApp::PmProduct.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::PmProduct.call(:create)
      assert res.success, 'Should always be able to create a pm_product'
    end

    def test_edit
      MasterfilesApp::BomsRepo.any_instance.stubs(:find_pm_product).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PmProduct.call(:edit, 1)
      assert res.success, 'Should be able to edit a pm_product'
    end

    def test_delete
      MasterfilesApp::BomsRepo.any_instance.stubs(:find_pm_product).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PmProduct.call(:delete, 1)
      assert res.success, 'Should be able to delete a pm_product'
    end
  end
end
