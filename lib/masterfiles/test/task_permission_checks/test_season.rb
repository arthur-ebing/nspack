# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestSeasonPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        season_group_id: 1,
        commodity_id: 1,
        season_code: 'ABC',
        description: 'ABC',
        season_year: '2010',
        start_date: '2010-01-01',
        end_date: '2010-01-01',
        active: true,
        season_group_code: 'ABC',
        commodity_code: 'ABC'
      }
      MasterfilesApp::Season.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::Season.call(:create)
      assert res.success, 'Should always be able to create a season'
    end

    def test_edit
      MasterfilesApp::CalendarRepo.any_instance.stubs(:find_season).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Season.call(:edit, 1)
      assert res.success, 'Should be able to edit a season'
    end

    def test_delete
      MasterfilesApp::CalendarRepo.any_instance.stubs(:find_season).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Season.call(:delete, 1)
      assert res.success, 'Should be able to delete a season'
    end
  end
end
