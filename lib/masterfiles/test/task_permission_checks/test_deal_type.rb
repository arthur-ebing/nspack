# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestDealTypePermission < Minitest::Test
    include Crossbeams::Responses
    include FinanceFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        deal_type: Faker::Lorem.unique.word,
        fixed_amount: false,
        active: true
      }
      MasterfilesApp::DealType.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::DealType.call(:create)
      assert res.success, 'Should always be able to create a deal_type'
    end

    def test_edit
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_deal_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::DealType.call(:edit, 1)
      assert res.success, 'Should be able to edit a deal_type'
    end

    def test_delete
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_deal_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::DealType.call(:delete, 1)
      assert res.success, 'Should be able to delete a deal_type'
    end
  end
end
