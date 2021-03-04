# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPaymentTermTypePermission < Minitest::Test
    include Crossbeams::Responses
    include FinanceFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        payment_term_type: Faker::Lorem.unique.word,
        active: true
      }
      MasterfilesApp::PaymentTermType.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::PaymentTermType.call(:create)
      assert res.success, 'Should always be able to create a payment_term_type'
    end

    def test_edit
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_payment_term_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PaymentTermType.call(:edit, 1)
      assert res.success, 'Should be able to edit a payment_term_type'
    end

    def test_delete
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_payment_term_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PaymentTermType.call(:delete, 1)
      assert res.success, 'Should be able to delete a payment_term_type'
    end
  end
end
