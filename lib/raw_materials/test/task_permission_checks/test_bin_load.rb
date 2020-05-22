# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module RawMaterialsApp
  class TestBinLoadPermission < Minitest::Test
    include Crossbeams::Responses
    include BinLoadFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        bin_load_purpose_id: 1,
        customer_party_role_id: 1,
        transporter_party_role_id: 1,
        dest_depot_id: 1,
        qty_bins: 1,
        shipped_at: '2010-01-01 12:00',
        shipped: false,
        completed_at: '2010-01-01 12:00',
        completed: false,
        active: true,
        purpose_code: 'ABC',
        customer: 'ABC',
        transporter: 'ABC',
        dest_depot: 'ABC',
        products: true,
        qty_product_bins: 1,
        qty_bins_available: 10,
        available_bin_ids: [1, 2, 3]
      }
      RawMaterialsApp::BinLoadFlat.new(base_attrs.merge(attrs))
    end

    def test_create
      res = RawMaterialsApp::TaskPermissionCheck::BinLoad.call(:create)
      assert res.success, 'Should always be able to create a bin_load'
    end

    def test_edit
      RawMaterialsApp::BinLoadRepo.any_instance.stubs(:find_bin_load_flat).returns(entity)
      res = RawMaterialsApp::TaskPermissionCheck::BinLoad.call(:edit, 1)
      assert res.success, 'Should be able to edit a bin_load'
    end

    def test_delete
      RawMaterialsApp::BinLoadRepo.any_instance.stubs(:find_bin_load_flat).returns(entity)
      res = RawMaterialsApp::TaskPermissionCheck::BinLoad.call(:delete, 1)
      assert res.success, 'Should be able to delete a bin_load'
    end

    def test_complete
      RawMaterialsApp::BinLoadRepo.any_instance.stubs(:find_bin_load_flat).returns(entity)
      res = RawMaterialsApp::TaskPermissionCheck::BinLoad.call(:complete, 1)
      assert res.success, 'Should be able to complete a bin_load'
    end
  end
end
