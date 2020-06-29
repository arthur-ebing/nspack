# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestInventoryCodePermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        inventory_code: Faker::Lorem.unique.word,
        description: 'ABC',
        edi_out_inventory_code: 'ABC',
        fruit_item_incentive_rate: 1.0,
        active: true
      }
      MasterfilesApp::InventoryCode.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::InventoryCode.call(:create)
      assert res.success, 'Should always be able to create a inventory_code'
    end

    def test_edit
      MasterfilesApp::FruitRepo.any_instance.stubs(:find_inventory_code).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::InventoryCode.call(:edit, 1)
      assert res.success, 'Should be able to edit a inventory_code'
    end

    def test_delete
      MasterfilesApp::FruitRepo.any_instance.stubs(:find_inventory_code).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::InventoryCode.call(:delete, 1)
      assert res.success, 'Should be able to delete a inventory_code'
    end
  end
end
