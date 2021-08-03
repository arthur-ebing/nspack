# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestFruitIndustryLevyInteractor < MiniTestWithHooks
    include PartyFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::PartyRepo)
    end

    def test_fruit_industry_levy
      MasterfilesApp::PartyRepo.any_instance.stubs(:find_fruit_industry_levy).returns(fake_fruit_industry_levy)
      entity = interactor.send(:fruit_industry_levy, 1)
      assert entity.is_a?(FruitIndustryLevy)
    end

    def test_create_fruit_industry_levy
      attrs = fake_fruit_industry_levy.to_h.reject { |k, _| k == :id }
      res = interactor.create_fruit_industry_levy(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(FruitIndustryLevy, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_fruit_industry_levy_fail
      attrs = fake_fruit_industry_levy(levy_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_fruit_industry_levy(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:levy_code]
    end

    def test_update_fruit_industry_levy
      id = create_fruit_industry_levy
      attrs = interactor.send(:repo).find_hash(:fruit_industry_levies, id).reject { |k, _| k == :id }
      value = attrs[:levy_code]
      attrs[:levy_code] = 'a_change'
      res = interactor.update_fruit_industry_levy(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(FruitIndustryLevy, res.instance)
      assert_equal 'a_change', res.instance.levy_code
      refute_equal value, res.instance.levy_code
    end

    def test_update_fruit_industry_levy_fail
      id = create_fruit_industry_levy
      attrs = interactor.send(:repo).find_hash(:fruit_industry_levies, id).reject { |k, _| %i[id levy_code].include?(k) }
      res = interactor.update_fruit_industry_levy(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:levy_code]
    end

    def test_delete_fruit_industry_levy
      id = create_fruit_industry_levy(force_create: true)
      assert_count_changed(:fruit_industry_levies, -1) do
        res = interactor.delete_fruit_industry_levy(id)
        assert res.success, res.message
      end
    end

    private

    def fruit_industry_levy_attrs
      {
        id: 1,
        levy_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
    end

    def fake_fruit_industry_levy(overrides = {})
      FruitIndustryLevy.new(fruit_industry_levy_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= FruitIndustryLevyInteractor.new(current_user, {}, {}, {})
    end
  end
end
