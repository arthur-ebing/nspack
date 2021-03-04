# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestDealTypeInteractor < MiniTestWithHooks
    include FinanceFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FinanceRepo)
    end

    def test_deal_type
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_deal_type).returns(fake_deal_type)
      entity = interactor.send(:deal_type, 1)
      assert entity.is_a?(DealType)
    end

    def test_create_deal_type
      attrs = fake_deal_type.to_h.reject { |k, _| k == :id }
      res = interactor.create_deal_type(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(DealType, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_deal_type_fail
      attrs = fake_deal_type(deal_type: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_deal_type(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:deal_type]
    end

    def test_update_deal_type
      id = create_deal_type
      attrs = interactor.send(:repo).find_hash(:deal_types, id).reject { |k, _| k == :id }
      value = attrs[:deal_type]
      attrs[:deal_type] = 'a_change'
      res = interactor.update_deal_type(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(DealType, res.instance)
      assert_equal 'a_change', res.instance.deal_type
      refute_equal value, res.instance.deal_type
    end

    def test_update_deal_type_fail
      id = create_deal_type
      attrs = interactor.send(:repo).find_hash(:deal_types, id).reject { |k, _| %i[id deal_type].include?(k) }
      res = interactor.update_deal_type(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:deal_type]
    end

    def test_delete_deal_type
      id = create_deal_type
      assert_count_changed(:deal_types, -1) do
        res = interactor.delete_deal_type(id)
        assert res.success, res.message
      end
    end

    private

    def deal_type_attrs
      {
        id: 1,
        deal_type: Faker::Lorem.unique.word,
        fixed_amount: false,
        active: true
      }
    end

    def fake_deal_type(overrides = {})
      DealType.new(deal_type_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= DealTypeInteractor.new(current_user, {}, {}, {})
    end
  end
end
