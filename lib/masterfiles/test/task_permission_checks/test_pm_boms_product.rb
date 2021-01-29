# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPmBomsProductPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        pm_product_id: 1,
        pm_bom_id: 1,
        uom_id: 1,
        quantity: 1.0,
        product_code: 'ABC',
        bom_code: 'ABC',
        uom_code: 'ABC',
        last_product: false
      }
      MasterfilesApp::PmBomsProduct.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::PmBomsProduct.call(:create)
      assert res.success, 'Should always be able to create a pm_boms_product'
    end

    def test_edit
      MasterfilesApp::BomRepo.any_instance.stubs(:find_pm_boms_product).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PmBomsProduct.call(:edit, 1)
      assert res.success, 'Should be able to edit a pm_boms_product'
    end

    def test_delete
      MasterfilesApp::BomRepo.any_instance.stubs(:find_pm_boms_product).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PmBomsProduct.call(:delete, 1)
      assert res.success, 'Should be able to delete a pm_boms_product'
    end

    def test_delete_fail
      MasterfilesApp::BomRepo.any_instance.stubs(:find_pm_boms_product).returns(entity(last_product: true))
      res = MasterfilesApp::TaskPermissionCheck::PmBomsProduct.call(:delete, 1)
      refute res.success, 'Should not be able to delete a pm_boms_product'
    end
  end
end
