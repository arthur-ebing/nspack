# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestOrderTypeInteractor < MiniTestWithHooks
    include FinanceFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FinanceRepo)
    end

    def test_order_type
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_order_type).returns(fake_order_type)
      entity = interactor.send(:order_type, 1)
      assert entity.is_a?(OrderType)
    end

    def test_create_order_type
      attrs = fake_order_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_order_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(OrderType, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_order_type_fail
      attrs = fake_order_type(order_type: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_order_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:order_type]
    end

    def test_update_order_type
      id = create_order_type
      attrs = interactor.send(:repo).find_hash(:order_types, id).reject { |k, _| k == :id }
      value = attrs[:order_type]
      attrs[:order_type] = 'a_change'
      res = interactor.update_order_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(OrderType, res.instance)
      assert_equal 'a_change', res.instance.order_type
      refute_equal value, res.instance.order_type
    end

    def test_update_order_type_fail
      id = create_order_type
      attrs = interactor.send(:repo).find_hash(:order_types, id).reject { |k, _| %i[id order_type].include?(k) }
      res = interactor.update_order_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:order_type]
    end

    def test_delete_order_type
      id = create_order_type
      assert_count_changed(:order_types, -1) do
        res = interactor.delete_order_type(id)
        assert res.success, res.message
      end
    end

    private

    def order_type_attrs
      {
        id: 1,
        order_type: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
    end

    def fake_order_type(overrides = {})
      OrderType.new(order_type_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= OrderTypeInteractor.new(current_user, {}, {}, {})
    end
  end
end
