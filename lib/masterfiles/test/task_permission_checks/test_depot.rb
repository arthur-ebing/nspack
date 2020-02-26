# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestDepotPermission < Minitest::Test
    include Crossbeams::Responses
    include DepotFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        city_id: 1,
        depot_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
      MasterfilesApp::Depot.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::Depot.call(:create)
      assert res.success, 'Should always be able to create a depot'
    end

    def test_edit
      MasterfilesApp::DepotRepo.any_instance.stubs(:find_depot).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Depot.call(:edit, 1)
      assert res.success, 'Should be able to edit a depot'
    end

    def test_delete
      MasterfilesApp::DepotRepo.any_instance.stubs(:find_depot).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Depot.call(:delete, 1)
      assert res.success, 'Should be able to delete a depot'
    end
  end
end
