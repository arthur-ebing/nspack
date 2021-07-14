# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestCustomerVarietyPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        variety_as_customer_variety_id: 1,
        packed_tm_group_id: 1,
        active: true,
        variety_as_customer_variety: 'ABC',
        packed_tm_group: 'ABC',
        marketing_varieties: %w[A B C]
      }
      MasterfilesApp::CustomerVariety.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::CustomerVariety.call(:create)
      assert res.success, 'Should always be able to create a customer_variety'
    end

    def test_edit
      MasterfilesApp::MarketingRepo.any_instance.stubs(:find_customer_variety).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::CustomerVariety.call(:edit, 1)
      assert res.success, 'Should be able to edit a customer_variety'
    end

    def test_delete
      MasterfilesApp::MarketingRepo.any_instance.stubs(:find_customer_variety).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::CustomerVariety.call(:delete, 1)
      assert res.success, 'Should be able to delete a customer_variety'
    end
  end
end
