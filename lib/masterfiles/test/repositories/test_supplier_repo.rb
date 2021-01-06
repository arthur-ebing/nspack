# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestSupplierRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_supplier_groups
      assert_respond_to repo, :for_select_suppliers
    end

    def test_crud_calls
      test_crud_calls_for :supplier_groups, name: :supplier_group, wrapper: SupplierGroup
      test_crud_calls_for :suppliers, name: :supplier, wrapper: Supplier
    end

    private

    def repo
      SupplierRepo.new
    end
  end
end
