# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestCustomerPaymentTermInteractor < MiniTestWithHooks
    include FinanceFactory
    include PartyFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FinanceRepo)
    end

    def test_customer_payment_term
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_customer_payment_term).returns(fake_customer_payment_term)
      entity = interactor.send(:customer_payment_term, 1)
      assert entity.is_a?(CustomerPaymentTerm)
    end

    def test_create_customer_payment_term
      attrs = fake_customer_payment_term.to_h.reject { |k, _| k == :id }
      res = interactor.create_customer_payment_term(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(CustomerPaymentTerm, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_customer_payment_term_fail
      attrs = fake_customer_payment_term(id: nil).to_h.reject { |k, _| k == :payment_term_id }
      res = interactor.create_customer_payment_term(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['is missing'], res.errors[:payment_term_id]
    end

    def test_update_customer_payment_term
      id = create_customer_payment_term
      attrs = interactor.send(:repo).find_hash(:customer_payment_terms, id).reject { |k, _| k == :id }
      value = attrs[:payment_term_id]
      a_change = create_payment_term
      attrs[:payment_term_id] = a_change
      res = interactor.update_customer_payment_term(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(CustomerPaymentTerm, res.instance)
      assert_equal a_change, res.instance.payment_term_id
      refute_equal value, res.instance.payment_term_id
    end

    def test_update_customer_payment_term_fail
      id = create_customer_payment_term
      attrs = interactor.send(:repo).find_hash(:customer_payment_terms, id).reject { |k, _| %i[id payment_term_id].include?(k) }
      res = interactor.update_customer_payment_term(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:payment_term_id]
    end

    def test_delete_customer_payment_term
      id = create_customer_payment_term
      assert_count_changed(:customer_payment_terms, -1) do
        res = interactor.delete_customer_payment_term(id)
        assert res.success, res.message
      end
    end

    private

    def customer_payment_term_attrs
      payment_term_id = create_payment_term
      customer_payment_term_set_id = create_customer_payment_term_set

      {
        id: 1,
        payment_term_id: payment_term_id,
        payment_term: 'ABC',
        customer_payment_term_set_id: customer_payment_term_set_id,
        customer_payment_term_set: 'ABC',
        active: true
      }
    end

    def fake_customer_payment_term(overrides = {})
      CustomerPaymentTerm.new(customer_payment_term_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= CustomerPaymentTermInteractor.new(current_user, {}, {}, {})
    end
  end
end
