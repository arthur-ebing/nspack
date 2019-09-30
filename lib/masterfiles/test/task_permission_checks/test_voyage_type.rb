# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestVoyageTypePermission < Minitest::Test
    include Crossbeams::Responses
    include VoyageTypeFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        voyage_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
      MasterfilesApp::VoyageType.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::VoyageType.call(:create)
      assert res.success, 'Should always be able to create a voyage_type'
    end

    def test_edit
      MasterfilesApp::VoyageTypeRepo.any_instance.stubs(:find_voyage_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::VoyageType.call(:edit, 1)
      assert res.success, 'Should be able to edit a voyage_type'
    end

    def test_delete
      MasterfilesApp::VoyageTypeRepo.any_instance.stubs(:find_voyage_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::VoyageType.call(:delete, 1)
      assert res.success, 'Should be able to delete a voyage_type'
    end
  end
end
