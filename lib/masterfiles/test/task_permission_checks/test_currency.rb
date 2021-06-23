# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestCurrencyPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        currency: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
      MasterfilesApp::Currency.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::Currency.call(:create)
      assert res.success, 'Should always be able to create a currency'
    end

    def test_edit
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_currency).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Currency.call(:edit, 1)
      assert res.success, 'Should be able to edit a currency'
    end

    def test_delete
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_currency).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Currency.call(:delete, 1)
      assert res.success, 'Should be able to delete a currency'
    end
  end
end
