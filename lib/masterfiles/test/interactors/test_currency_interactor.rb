# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestCurrencyInteractor < MiniTestWithHooks
    include FinanceFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FinanceRepo)
    end

    def test_currency
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_currency).returns(fake_currency)
      entity = interactor.send(:currency, 1)
      assert entity.is_a?(Currency)
    end

    def test_create_currency
      attrs = fake_currency.to_h.reject { |k, _| k == :id }
      res = interactor.create_currency(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Currency, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_currency_fail
      attrs = fake_currency(currency: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_currency(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:currency]
    end

    def test_update_currency
      id = create_currency
      attrs = interactor.send(:repo).find_hash(:currencies, id).reject { |k, _| k == :id }
      value = attrs[:currency]
      attrs[:currency] = 'a_change'
      res = interactor.update_currency(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Currency, res.instance)
      assert_equal 'a_change', res.instance.currency
      refute_equal value, res.instance.currency
    end

    def test_update_currency_fail
      id = create_currency
      attrs = interactor.send(:repo).find_hash(:currencies, id).reject { |k, _| %i[id currency].include?(k) }
      res = interactor.update_currency(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:currency]
    end

    def test_delete_currency
      id = create_currency
      assert_count_changed(:currencies, -1) do
        res = interactor.delete_currency(id)
        assert res.success, res.message
      end
    end

    private

    def currency_attrs
      {
        id: 1,
        currency: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
    end

    def fake_currency(overrides = {})
      Currency.new(currency_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= CurrencyInteractor.new(current_user, {}, {}, {})
    end
  end
end
