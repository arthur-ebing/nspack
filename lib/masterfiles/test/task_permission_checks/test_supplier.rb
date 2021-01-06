# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestSupplierPermission < Minitest::Test
    include Crossbeams::Responses
    include SupplierFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        supplier_party_role_id: 1,
        supplier: Faker::Lorem.unique.word,
        supplier_group_ids: [1, 2, 3],
        supplier_group_codes: %i[A B C],
        farm_ids: [1, 2, 3],
        farm_codes: %i[A B C],
        active: true
      }
      MasterfilesApp::Supplier.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::Supplier.call(:create)
      assert res.success, 'Should always be able to create a supplier'
    end

    def test_edit
      MasterfilesApp::SupplierRepo.any_instance.stubs(:find_supplier).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Supplier.call(:edit, 1)
      assert res.success, 'Should be able to edit a supplier'
    end

    def test_delete
      MasterfilesApp::SupplierRepo.any_instance.stubs(:find_supplier).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Supplier.call(:delete, 1)
      assert res.success, 'Should be able to delete a supplier'
    end
  end
end
