# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestCustomerPaymentTermSetInteractor < MiniTestWithHooks
    include FinanceFactory
    include PartyFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FinanceRepo)
    end

    def test_customer_payment_term_set
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_customer_payment_term_set).returns(fake_customer_payment_term_set)
      entity = interactor.send(:customer_payment_term_set, 1)
      assert entity.is_a?(CustomerPaymentTermSet)
    end

    def test_create_customer_payment_term_set
      attrs = fake_customer_payment_term_set.to_h.reject { |k, _| k == :id }
      res = interactor.create_customer_payment_term_set(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(CustomerPaymentTermSet, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_customer_payment_term_set_fail
      attrs = fake_customer_payment_term_set(customer_id: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_customer_payment_term_set(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:customer_id]
    end

    def test_update_customer_payment_term_set
      id = create_customer_payment_term_set
      attrs = interactor.send(:repo).find_hash(:customer_payment_term_sets, id).reject { |k, _| k == :id }
      value = attrs[:customer_id]
      a_change = create_customer
      attrs[:customer_id] = a_change
      res = interactor.update_customer_payment_term_set(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(CustomerPaymentTermSet, res.instance)
      assert_equal a_change, res.instance.customer_id
      refute_equal value, res.instance.id
    end

    def test_update_customer_payment_term_set_fail
      id = create_customer_payment_term_set
      attrs = interactor.send(:repo).find_hash(:customer_payment_term_sets, id).reject { |k, _| %i[id customer_id].include?(k) }
      res = interactor.update_customer_payment_term_set(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:customer_id]
    end

    def test_delete_customer_payment_term_set
      id = create_customer_payment_term_set
      assert_count_changed(:customer_payment_term_sets, -1) do
        res = interactor.delete_customer_payment_term_set(id)
        assert res.success, res.message
      end
    end

    private

    def customer_payment_term_set_attrs
      incoterm_id = create_incoterm
      deal_type_id = create_deal_type
      customer_id = create_customer

      {
        id: 1,
        incoterm_id: incoterm_id,
        incoterm: 'ABC',
        deal_type_id: deal_type_id,
        deal_type: 'ABC',
        customer_id: customer_id,
        customer: 'ABC',
        customer_payment_term_set: 'ABC',
        active: true
      }
    end

    def fake_customer_payment_term_set(overrides = {})
      CustomerPaymentTermSet.new(customer_payment_term_set_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= CustomerPaymentTermSetInteractor.new(current_user, {}, {}, {})
    end
  end
end
