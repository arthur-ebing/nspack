# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestColorPercentageInteractor < MiniTestWithHooks
    include CommodityFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::CommodityRepo)
    end

    def test_color_percentage
      MasterfilesApp::CommodityRepo.any_instance.stubs(:find_color_percentage).returns(fake_color_percentage)
      entity = interactor.send(:color_percentage, 1)
      assert entity.is_a?(ColorPercentage)
    end

    def test_create_color_percentage
      attrs = fake_color_percentage.to_h.reject { |k, _| k == :id }
      res = interactor.create_color_percentage(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(ColorPercentageFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_color_percentage_fail
      attrs = fake_color_percentage(description: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_color_percentage(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:description]
    end

    def test_update_color_percentage
      id = create_color_percentage
      attrs = interactor.send(:repo).find_hash(:color_percentages, id).reject { |k, _| k == :id }
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_color_percentage(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(ColorPercentageFlat, res.instance)
      assert_equal 'a_change', res.instance.description
      refute_equal value, res.instance.description
    end

    def test_update_color_percentage_fail
      id = create_color_percentage
      attrs = interactor.send(:repo).find_hash(:color_percentages, id).reject { |k, _| %i[id description].include?(k) }
      res = interactor.update_color_percentage(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:description]
    end

    def test_delete_color_percentage
      id = create_color_percentage(force_create: true)
      assert_count_changed(:color_percentages, -1) do
        res = interactor.delete_color_percentage(id)
        assert res.success, res.message
      end
    end

    private

    def color_percentage_attrs
      commodity_id = create_commodity

      {
        id: 1,
        commodity_id: commodity_id,
        color_percentage: 1,
        description: Faker::Lorem.unique.word,
        active: true
      }
    end

    def fake_color_percentage(overrides = {})
      ColorPercentage.new(color_percentage_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= ColorPercentageInteractor.new(current_user, {}, {}, {})
    end
  end
end
