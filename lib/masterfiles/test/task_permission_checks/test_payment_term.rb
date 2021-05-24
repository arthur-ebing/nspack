# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPaymentTermPermission < Minitest::Test
    include Crossbeams::Responses
    include FinanceFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        incoterm_id: 1,
        incoterm: 'ABC',
        deal_type_id: 1,
        deal_type: 'ABC',
        payment_term: 'ABC',
        payment_term_date_type_id: 1,
        payment_term_date_type: 'ABC',
        short_description: Faker::Lorem.unique.word,
        long_description: 'ABC',
        percentage: 1,
        days: 1,
        amount_per_carton: 1.0,
        for_liquidation: false,
        active: true
      }
      MasterfilesApp::PaymentTerm.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::PaymentTerm.call(:create)
      assert res.success, 'Should always be able to create a payment_term'
    end

    def test_edit
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_payment_term).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PaymentTerm.call(:edit, 1)
      assert res.success, 'Should be able to edit a payment_term'
    end

    def test_delete
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_payment_term).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PaymentTerm.call(:delete, 1)
      assert res.success, 'Should be able to delete a payment_term'
    end
  end
end
