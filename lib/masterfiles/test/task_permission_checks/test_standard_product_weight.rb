# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestStandardProductWeightPermission < Minitest::Test
    include Crossbeams::Responses
    include StandardProductWeightFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        commodity_id: 1,
        standard_pack_id: 1,
        gross_weight: 1.0,
        nett_weight: 1.0,
        active: true,
        standard_carton_nett_weight: 1.0,
        ratio_to_standard_carton: 1.0,
        is_standard_carton: false
      }
      MasterfilesApp::StandardProductWeight.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::StandardProductWeight.call(:create)
      assert res.success, 'Should always be able to create a standard_product_weight'
    end

    def test_edit
      MasterfilesApp::FruitSizeRepo.any_instance.stubs(:find_standard_product_weight_flat).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::StandardProductWeight.call(:edit, 1)
      assert res.success, 'Should be able to edit a standard_product_weight'
    end

    def test_delete
      MasterfilesApp::FruitSizeRepo.any_instance.stubs(:find_standard_product_weight_flat).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::StandardProductWeight.call(:delete, 1)
      assert res.success, 'Should be able to delete a standard_product_weight'
    end
  end
end
