# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestOrderTypePermission < Minitest::Test
    include Crossbeams::Responses
    include FinanceFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        order_type: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
      MasterfilesApp::OrderType.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::OrderType.call(:create)
      assert res.success, 'Should always be able to create a order_type'
    end

    def test_edit
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_order_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::OrderType.call(:edit, 1)
      assert res.success, 'Should be able to edit a order_type'
    end

    def test_delete
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_order_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::OrderType.call(:delete, 1)
      assert res.success, 'Should be able to delete a order_type'
    end
  end
end
