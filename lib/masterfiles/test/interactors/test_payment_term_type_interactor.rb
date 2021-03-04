# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPaymentTermTypeInteractor < MiniTestWithHooks
    include FinanceFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FinanceRepo)
    end

    def test_payment_term_type
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_payment_term_type).returns(fake_payment_term_type)
      entity = interactor.send(:payment_term_type, 1)
      assert entity.is_a?(PaymentTermType)
    end

    def test_create_payment_term_type
      attrs = fake_payment_term_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_payment_term_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PaymentTermType, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_payment_term_type_fail
      attrs = fake_payment_term_type(payment_term_type: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_payment_term_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:payment_term_type]
    end

    def test_update_payment_term_type
      id = create_payment_term_type
      attrs = interactor.send(:repo).find_hash(:payment_term_types, id).reject { |k, _| k == :id }
      value = attrs[:payment_term_type]
      attrs[:payment_term_type] = 'a_change'
      res = interactor.update_payment_term_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PaymentTermType, res.instance)
      assert_equal 'a_change', res.instance.payment_term_type
      refute_equal value, res.instance.payment_term_type
    end

    def test_update_payment_term_type_fail
      id = create_payment_term_type
      attrs = interactor.send(:repo).find_hash(:payment_term_types, id).reject { |k, _| %i[id payment_term_type].include?(k) }
      res = interactor.update_payment_term_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:payment_term_type]
    end

    def test_delete_payment_term_type
      id = create_payment_term_type
      assert_count_changed(:payment_term_types, -1) do
        res = interactor.delete_payment_term_type(id)
        assert res.success, res.message
      end
    end

    private

    def payment_term_type_attrs
      {
        id: 1,
        payment_term_type: Faker::Lorem.unique.word,
        active: true
      }
    end

    def fake_payment_term_type(overrides = {})
      PaymentTermType.new(payment_term_type_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PaymentTermTypeInteractor.new(current_user, {}, {}, {})
    end
  end
end
