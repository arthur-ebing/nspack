# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestSeasonInteractor < MiniTestWithHooks
    include CalendarFactory
    include CommodityFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::CalendarRepo)
    end

    def test_season
      MasterfilesApp::CalendarRepo.any_instance.stubs(:find_season).returns(fake_season)
      entity = interactor.send(:season, 1)
      assert entity.is_a?(Season)
    end

    def test_create_season
      attrs = fake_season.to_h.reject { |k, _| k == :id }
      res = interactor.create_season(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Season, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_season_fail
      attrs = fake_season(season_code: nil).to_h.reject { |k, _| k == :season_group_id }
      res = interactor.create_season(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['is missing'], res.errors[:season_group_id]
    end

    def test_update_season
      id = create_season
      attrs = interactor.send(:repo).find_season(id)
      attrs = attrs.to_h
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_season(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Season, res.instance)
      assert_equal 'a_change', res.instance.description
      refute_equal value, res.instance.description
    end

    def test_update_season_fail
      id = create_season
      attrs = interactor.send(:repo).find_season(id)
      attrs = attrs.to_h
      attrs.delete(:season_group_id)
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_season(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:season_group_id]
      after = interactor.send(:repo).find_season(id)
      after = after.to_h
      refute_equal 'a_change', after[:description]
      assert_equal value, after[:description]
    end

    def test_delete_season
      id = create_season
      assert_count_changed(:seasons, -1) do
        res = interactor.delete_season(id)
        assert res.success, res.message
      end
    end

    private

    def season_attrs
      season_group_id = create_season_group
      commodity_id = create_commodity

      {
        id: 1,
        season_group_id: season_group_id,
        commodity_id: commodity_id,
        season_code: Faker::Lorem.unique.word,
        description: 'ABC',
        season_year: 2010,
        start_date: '2010-01-01',
        end_date: '2010-01-01',
        active: true,
        season_group_code: 'ABC',
        commodity_code: 'ABC'
      }
    end

    def fake_season(overrides = {})
      Season.new(season_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= SeasonInteractor.new(current_user, {}, {}, {})
    end
  end
end
