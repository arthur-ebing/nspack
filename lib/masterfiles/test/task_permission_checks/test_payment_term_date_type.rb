# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPaymentTermDateTypePermission < Minitest::Test
    include Crossbeams::Responses
    include FinanceFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        type_of_date: Faker::Lorem.unique.word,
        no_days_after_etd: 1,
        no_days_after_eta: 1,
        no_days_after_atd: 1,
        no_days_after_ata: 1,
        no_days_after_invoice: 1,
        no_days_after_invoice_sent: 1,
        no_days_after_container_load: 1,
        anchor_to_date: 'ABC',
        adjust_anchor_date_to_month_end: false,
        active: true
      }
      MasterfilesApp::PaymentTermDateType.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::PaymentTermDateType.call(:create)
      assert res.success, 'Should always be able to create a payment_term_date_type'
    end

    def test_edit
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_payment_term_date_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PaymentTermDateType.call(:edit, 1)
      assert res.success, 'Should be able to edit a payment_term_date_type'
    end

    def test_delete
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_payment_term_date_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PaymentTermDateType.call(:delete, 1)
      assert res.success, 'Should be able to delete a payment_term_date_type'
    end
  end
end
