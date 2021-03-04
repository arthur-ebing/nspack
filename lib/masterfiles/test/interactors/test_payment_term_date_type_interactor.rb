# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPaymentTermDateTypeInteractor < MiniTestWithHooks
    include FinanceFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FinanceRepo)
    end

    def test_payment_term_date_type
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_payment_term_date_type).returns(fake_payment_term_date_type)
      entity = interactor.send(:payment_term_date_type, 1)
      assert entity.is_a?(PaymentTermDateType)
    end

    def test_create_payment_term_date_type
      attrs = fake_payment_term_date_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_payment_term_date_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PaymentTermDateType, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_payment_term_date_type_fail
      attrs = fake_payment_term_date_type(type_of_date: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_payment_term_date_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:type_of_date]
    end

    def test_update_payment_term_date_type
      id = create_payment_term_date_type
      attrs = interactor.send(:repo).find_hash(:payment_term_date_types, id).reject { |k, _| k == :id }
      value = attrs[:type_of_date]
      attrs[:type_of_date] = 'a_change'
      res = interactor.update_payment_term_date_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PaymentTermDateType, res.instance)
      assert_equal 'a_change', res.instance.type_of_date
      refute_equal value, res.instance.type_of_date
    end

    def test_update_payment_term_date_type_fail
      id = create_payment_term_date_type
      attrs = interactor.send(:repo).find_hash(:payment_term_date_types, id).reject { |k, _| %i[id type_of_date].include?(k) }
      res = interactor.update_payment_term_date_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:type_of_date]
    end

    def test_delete_payment_term_date_type
      id = create_payment_term_date_type
      assert_count_changed(:payment_term_date_types, -1) do
        res = interactor.delete_payment_term_date_type(id)
        assert res.success, res.message
      end
    end

    private

    def payment_term_date_type_attrs
      {
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
    end

    def fake_payment_term_date_type(overrides = {})
      PaymentTermDateType.new(payment_term_date_type_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PaymentTermDateTypeInteractor.new(current_user, {}, {}, {})
    end
  end
end
