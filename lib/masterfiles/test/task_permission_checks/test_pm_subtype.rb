# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPmSubtypePermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        pm_type_id: 1,
        subtype_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true,
        pm_type_code: 'ABC',
        short_code: 'ABC'
      }
      MasterfilesApp::PmSubtype.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::PmSubtype.call(:create)
      assert res.success, 'Should always be able to create a pm_subtype'
    end

    def test_edit
      MasterfilesApp::BomsRepo.any_instance.stubs(:find_pm_subtype).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PmSubtype.call(:edit, 1)
      assert res.success, 'Should be able to edit a pm_subtype'
    end

    def test_delete
      MasterfilesApp::BomsRepo.any_instance.stubs(:find_pm_subtype).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PmSubtype.call(:delete, 1)
      assert res.success, 'Should be able to delete a pm_subtype'
    end
  end
end
