# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module RawMaterialsApp
  class TestBinLoadProductPermission < Minitest::Test
    include Crossbeams::Responses
    include BinLoadFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        bin_load_id: 1,
        qty_bins: 1,
        cultivar_id: 1,
        cultivar_group_id: 1,
        rmt_container_material_type_id: 1,
        rmt_material_owner_party_role_id: 1,
        farm_id: 1,
        puc_id: 1,
        orchard_id: 1,
        rmt_class_id: 1,
        cultivar_group_code: 'ABC',
        cultivar_name: 'ABC',
        farm_code: 'ABC',
        puc_code: 'ABC',
        orchard_code: 'ABC',
        rmt_class_code: 'ABC',
        container_material_type_code: 'ABC',
        container_material_owner: 'ABC',
        product_code: 'ABC',
        completed: false,
        status: 'ABC'
      }
      RawMaterialsApp::BinLoadProductFlat.new(base_attrs.merge(attrs))
    end

    def test_create
      res = RawMaterialsApp::TaskPermissionCheck::BinLoadProduct.call(:create)
      assert res.success, 'Should always be able to create a bin_load_product'
    end

    def test_edit
      RawMaterialsApp::BinLoadRepo.any_instance.stubs(:find_bin_load_product_flat).returns(entity)
      res = RawMaterialsApp::TaskPermissionCheck::BinLoadProduct.call(:edit, 1)
      assert res.success, 'Should be able to edit a bin_load_product'
    end

    def test_delete
      RawMaterialsApp::BinLoadRepo.any_instance.stubs(:find_bin_load_product_flat).returns(entity)
      res = RawMaterialsApp::TaskPermissionCheck::BinLoadProduct.call(:delete, 1)
      assert res.success, 'Should be able to delete a bin_load_product'
    end
  end
end
