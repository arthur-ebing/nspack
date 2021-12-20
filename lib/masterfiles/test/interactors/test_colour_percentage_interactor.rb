# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestColourPercentageInteractor < MiniTestWithHooks
    include CommodityFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::CommodityRepo)
    end

    def test_colour_percentage
      MasterfilesApp::CommodityRepo.any_instance.stubs(:find_colour_percentage).returns(fake_colour_percentage)
      entity = interactor.send(:colour_percentage, 1)
      assert entity.is_a?(ColourPercentage)
    end

    def test_create_colour_percentage
      attrs = fake_colour_percentage.to_h.reject { |k, _| k == :id }
      res = interactor.create_colour_percentage(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(ColourPercentageFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_colour_percentage_fail
      attrs = fake_colour_percentage(description: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_colour_percentage(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:description]
    end

    def test_update_colour_percentage
      id = create_colour_percentage
      attrs = interactor.send(:repo).find_hash(:colour_percentages, id).reject { |k, _| k == :id }
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_colour_percentage(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(ColourPercentageFlat, res.instance)
      assert_equal 'a_change', res.instance.description
      refute_equal value, res.instance.description
    end

    def test_update_colour_percentage_fail
      id = create_colour_percentage
      attrs = interactor.send(:repo).find_hash(:colour_percentages, id).reject { |k, _| %i[id description].include?(k) }
      res = interactor.update_colour_percentage(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:description]
    end

    def test_delete_colour_percentage
      id = create_colour_percentage(force_create: true)
      assert_count_changed(:colour_percentages, -1) do
        res = interactor.delete_colour_percentage(id)
        assert res.success, res.message
      end
    end

    private

    def colour_percentage_attrs
      commodity_id = create_commodity

      {
        id: 1,
        commodity_id: commodity_id,
        colour_percentage: 'ABC',
        description: Faker::Lorem.unique.word,
        active: true
      }
    end

    def fake_colour_percentage(overrides = {})
      ColourPercentage.new(colour_percentage_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= ColourPercentageInteractor.new(current_user, {}, {}, {})
    end
  end
end
