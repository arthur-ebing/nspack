# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestCustomerInteractor < MiniTestWithHooks
    include FinanceFactory
    include PartyFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FinanceRepo)
    end

    def test_customer
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_customer).returns(fake_customer)
      entity = interactor.send(:customer, 1)
      assert entity.is_a?(Customer)
    end

    def test_create_customer
      attrs = customer_attrs.reject { |k, _| k == :id }
      create_role(name: AppConst::ROLE_CUSTOMER)
      attrs[:customer_party_role_id] = 'Create New Organization'
      res = interactor.create_customer(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Customer, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_customer_fail
      attrs = fake_customer(default_currency_id: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_customer(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:default_currency_id]
    end

    def test_update_customer
      id = create_customer
      attrs = interactor.send(:repo).find_hash(:customers, id).reject { |k, _| k == :id }
      value = attrs[:default_currency_id]
      a_change = create_currency
      attrs[:default_currency_id] = a_change
      res = interactor.update_customer(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Customer, res.instance)
      assert_equal a_change, res.instance.default_currency_id
      refute_equal value, res.instance.id
    end

    def test_update_customer_fail
      id = create_customer
      attrs = interactor.send(:repo).find_hash(:customers, id).reject { |k, _| %i[id default_currency_id].include?(k) }
      res = interactor.update_customer(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:default_currency_id]
    end

    def test_delete_customer
      id = create_customer
      assert_count_changed(:customers, -1) do
        res = interactor.delete_customer(id)
        assert res.success, res.message
      end
    end

    private

    def customer_attrs
      currency_id = create_currency
      party_role_id = create_party_role

      {
        id: 1,
        customer_party_role_id: party_role_id,
        customer: 'ABC',
        currency_ids: [currency_id],
        currencies: %w[ZAR],
        default_currency_id: currency_id,
        default_currency: 'ZAR',
        contact_person_ids: [party_role_id],
        contact_people: %w[ABC],
        active: true,
        # organization
        short_description: 'ABC',
        medium_description: Faker::Lorem.unique.word,
        long_description: 'ABC',
        vat_number: 'ABC',
        company_reg_no: 'ABC'
      }
    end

    def fake_customer(overrides = {})
      Customer.new(customer_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= CustomerInteractor.new(current_user, {}, {}, {})
    end
  end
end
