# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestCustomerPaymentTermSetPermission < Minitest::Test
    include Crossbeams::Responses
    include FinanceFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        incoterm_id: 1,
        incoterm: 'ABC',
        deal_type_id: 1,
        deal_type: 'ABC',
        customer_id: 1,
        customer: 'ABC',
        customer_payment_term_set: 'ABC',
        active: true
      }
      MasterfilesApp::CustomerPaymentTermSet.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::CustomerPaymentTermSet.call(:create)
      assert res.success, 'Should always be able to create a customer_payment_term_set'
    end

    def test_edit
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_customer_payment_term_set).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::CustomerPaymentTermSet.call(:edit, 1)
      assert res.success, 'Should be able to edit a customer_payment_term_set'
    end

    def test_delete
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_customer_payment_term_set).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::CustomerPaymentTermSet.call(:delete, 1)
      assert res.success, 'Should be able to delete a customer_payment_term_set'
    end
  end
end
