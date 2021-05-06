# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestFinanceRepo < MiniTestWithHooks
    def test_for_selects
      assert_respond_to repo, :for_select_currencies
      assert_respond_to repo, :for_select_customers
      assert_respond_to repo, :for_select_deal_types
      assert_respond_to repo, :for_select_incoterms
      assert_respond_to repo, :for_select_customer_payment_term_sets
      assert_respond_to repo, :for_select_payment_term_date_types
      assert_respond_to repo, :for_select_payment_term_types
      assert_respond_to repo, :for_select_payment_terms
      assert_respond_to repo, :for_select_customer_payment_terms
      assert_respond_to repo, :for_select_order_types
    end

    def test_crud_calls
      test_crud_calls_for :currencies, name: :currency, wrapper: Currency
      test_crud_calls_for :customers, name: :customer, wrapper: Customer
      test_crud_calls_for :deal_types, name: :deal_type, wrapper: DealType
      test_crud_calls_for :incoterms, name: :incoterm, wrapper: Incoterm
      test_crud_calls_for :customer_payment_term_sets, name: :customer_payment_term_set, wrapper: CustomerPaymentTermSet
      test_crud_calls_for :payment_term_date_types, name: :payment_term_date_type, wrapper: PaymentTermDateType
      test_crud_calls_for :payment_term_types, name: :payment_term_type, wrapper: PaymentTermType
      test_crud_calls_for :payment_terms, name: :payment_term, wrapper: PaymentTerm
      test_crud_calls_for :customer_payment_terms, name: :customer_payment_term, wrapper: CustomerPaymentTerm
      test_crud_calls_for :order_types, name: :order_type, wrapper: OrderType
    end

    private

    def repo
      FinanceRepo.new
    end
  end
end
