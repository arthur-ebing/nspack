# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPaymentTermInteractor < MiniTestWithHooks
    include FinanceFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FinanceRepo)
    end

    def test_payment_term
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_payment_term).returns(fake_payment_term)
      entity = interactor.send(:payment_term, 1)
      assert entity.is_a?(PaymentTerm)
    end

    def test_create_payment_term
      attrs = fake_payment_term.to_h.reject { |k, _| k == :id }
      res = interactor.create_payment_term(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PaymentTerm, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_payment_term_fail
      attrs = fake_payment_term(short_description: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_payment_term(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:short_description]
    end

    def test_update_payment_term
      id = create_payment_term
      attrs = interactor.send(:repo).find_hash(:payment_terms, id).reject { |k, _| k == :id }
      value = attrs[:short_description]
      attrs[:short_description] = 'a_change'
      res = interactor.update_payment_term(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PaymentTerm, res.instance)
      assert_equal 'a_change', res.instance.short_description
      refute_equal value, res.instance.short_description
    end

    def test_update_payment_term_fail
      id = create_payment_term
      attrs = interactor.send(:repo).find_hash(:payment_terms, id).reject { |k, _| %i[id short_description].include?(k) }
      res = interactor.update_payment_term(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:short_description]
    end

    def test_delete_payment_term
      id = create_payment_term
      assert_count_changed(:payment_terms, -1) do
        res = interactor.delete_payment_term(id)
        assert res.success, res.message
      end
    end

    private

    def payment_term_attrs
      incoterm_id = create_incoterm
      deal_type_id = create_deal_type
      payment_term_date_type_id = create_payment_term_date_type

      {
        id: 1,
        incoterm_id: incoterm_id,
        incoterm: 'ABC',
        deal_type_id: deal_type_id,
        deal_type: 'ABC',
        payment_term: 'ABC',
        payment_term_date_type_id: payment_term_date_type_id,
        payment_term_date_type: 'ABC',
        short_description: Faker::Lorem.unique.word,
        long_description: 'ABC',
        percentage: 1,
        days: 1,
        amount_per_carton: 1.0,
        for_liquidation: false,
        active: true
      }
    end

    def fake_payment_term(overrides = {})
      PaymentTerm.new(payment_term_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PaymentTermInteractor.new(current_user, {}, {}, {})
    end
  end
end
