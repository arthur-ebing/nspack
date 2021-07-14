# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestCustomerVarietyInteractor < MiniTestWithHooks
    include MarketingFactory
    include TargetMarketFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::MarketingRepo)
    end

    def test_customer_variety
      MasterfilesApp::MarketingRepo.any_instance.stubs(:find_customer_variety).returns(fake_customer_variety)
      entity = interactor.send(:customer_variety, 1)
      assert entity.is_a?(CustomerVariety)
    end

    def test_create_customer_variety
      attrs = fake_customer_variety.to_h.reject { |k, _| k == :id }
      id = create_customer_variety_variety(force_create: true)
      attrs[:customer_variety_varieties] = interactor.send(:repo).find_customer_variety_variety(id)[:marketing_variety_id]
      res = interactor.create_customer_variety(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(CustomerVariety, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_customer_variety_fail
      attrs = fake_customer_variety(variety_as_customer_variety_id: nil).to_h.reject { |k, _| k == :id }
      id = create_customer_variety_variety(force_create: true)
      attrs[:customer_variety_varieties] = interactor.send(:repo).find_customer_variety_variety(id)[:marketing_variety_id]
      res = interactor.create_customer_variety(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:variety_as_customer_variety_id]
    end

    def test_update_customer_variety
      id = create_customer_variety
      variety_as_customer_variety_id = create_marketing_variety(force_create: true)
      attrs = interactor.send(:repo).find_customer_variety(id)
      attrs = attrs.to_h
      value = attrs[:variety_as_customer_variety_id]
      attrs[:variety_as_customer_variety_id] = variety_as_customer_variety_id
      res = interactor.update_customer_variety(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(CustomerVariety, res.instance)
      assert_equal variety_as_customer_variety_id, res.instance.variety_as_customer_variety_id
      refute_equal value, res.instance.variety_as_customer_variety_id
    end

    def test_update_customer_variety_fail
      id = create_customer_variety
      attrs = interactor.send(:repo).find_customer_variety(id)
      attrs = attrs.to_h
      attrs.delete(:packed_tm_group_id)
      value = attrs[:variety_as_customer_variety_id]
      attrs[:variety_as_customer_variety_id] = 1
      res = interactor.update_customer_variety(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:packed_tm_group_id]
      after = interactor.send(:repo).find_customer_variety(id)
      after = after.to_h
      refute_equal 1, after[:variety_as_customer_variety_id]
      assert_equal value, after[:variety_as_customer_variety_id]
    end

    def test_delete_customer_variety
      id = create_customer_variety
      assert_count_changed(:customer_varieties, -1) do
        res = interactor.delete_customer_variety(id)
        assert res.success, res.message
      end
    end

    private

    def customer_variety_attrs
      marketing_variety_id = create_marketing_variety(force_create: true)
      target_market_group_id = create_target_market_group

      {
        id: 1,
        variety_as_customer_variety_id: marketing_variety_id,
        packed_tm_group_id: target_market_group_id,
        active: true,
        variety_as_customer_variety: 'ABC',
        marketing_varieties: %w[A B C],
        packed_tm_group: 'ABC'
      }
    end

    def fake_customer_variety(overrides = {})
      CustomerVariety.new(customer_variety_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= CustomerVarietyInteractor.new(current_user, {}, {}, {})
    end
  end
end
