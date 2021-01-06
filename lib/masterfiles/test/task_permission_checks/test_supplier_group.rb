# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestSupplierGroupPermission < Minitest::Test
    include Crossbeams::Responses
    include SupplierFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        supplier_group_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
      MasterfilesApp::SupplierGroup.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::SupplierGroup.call(:create)
      assert res.success, 'Should always be able to create a supplier_group'
    end

    def test_edit
      MasterfilesApp::SupplierRepo.any_instance.stubs(:find_supplier_group).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::SupplierGroup.call(:edit, 1)
      assert res.success, 'Should be able to edit a supplier_group'
    end

    def test_delete
      MasterfilesApp::SupplierRepo.any_instance.stubs(:find_supplier_group).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::SupplierGroup.call(:delete, 1)
      assert res.success, 'Should be able to delete a supplier_group'
    end
  end
end
