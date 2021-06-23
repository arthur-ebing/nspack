# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestSeasonGroupInteractor < MiniTestWithHooks
    include CalendarFactory
    include CommodityFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::CalendarRepo)
    end

    def test_season_group
      MasterfilesApp::CalendarRepo.any_instance.stubs(:find_season_group).returns(fake_season_group)
      entity = interactor.send(:season_group, 1)
      assert entity.is_a?(SeasonGroup)
    end

    def test_create_season_group
      attrs = fake_season_group.to_h.reject { |k, _| k == :id }
      res = interactor.create_season_group(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(SeasonGroup, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_season_group_fail
      attrs = fake_season_group(season_group_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_season_group(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:season_group_code]
    end

    def test_update_season_group
      id = create_season_group
      attrs = interactor.send(:repo).find_hash(:season_groups, id).reject { |k, _| k == :id }
      value = attrs[:season_group_code]
      attrs[:season_group_code] = 'a_change'
      res = interactor.update_season_group(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(SeasonGroup, res.instance)
      assert_equal 'a_change', res.instance.season_group_code
      refute_equal value, res.instance.season_group_code
    end

    def test_update_season_group_fail
      id = create_season_group
      attrs = interactor.send(:repo).find_hash(:season_groups, id).reject { |k, _| %i[id season_group_code].include?(k) }
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_season_group(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:season_group_code]
      after = interactor.send(:repo).find_hash(:season_groups, id)
      refute_equal 'a_change', after[:description]
      assert_equal value, after[:description]
    end

    def test_delete_season_group
      id = create_season_group(force_create: true)
      assert_count_changed(:season_groups, -1) do
        res = interactor.delete_season_group(id)
        assert res.success, res.message
      end
    end

    private

    def season_group_attrs
      {
        id: 1,
        season_group_code: Faker::Lorem.unique.word,
        description: 'ABC',
        season_group_year: 1,
        active: true
      }
    end

    def fake_season_group(overrides = {})
      SeasonGroup.new(season_group_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= SeasonGroupInteractor.new(current_user, {}, {}, {})
    end
  end
end
