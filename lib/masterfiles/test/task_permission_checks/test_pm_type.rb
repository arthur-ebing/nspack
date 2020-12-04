# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPmTypePermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        pm_composition_level_id: 1,
        pm_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true,
        composition_level: 'ABC',
        short_code: 'ABC'
      }
      MasterfilesApp::PmType.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::PmType.call(:create)
      assert res.success, 'Should always be able to create a pm_type'
    end

    def test_edit
      MasterfilesApp::BomsRepo.any_instance.stubs(:find_pm_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PmType.call(:edit, 1)
      assert res.success, 'Should be able to edit a pm_type'
    end

    def test_delete
      MasterfilesApp::BomsRepo.any_instance.stubs(:find_pm_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PmType.call(:delete, 1)
      assert res.success, 'Should be able to delete a pm_type'
    end
  end
end
