# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPmCompositionLevelPermission < Minitest::Test
    include Crossbeams::Responses
    include PackagingFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        composition_level: 1,
        description: Faker::Lorem.unique.word,
        active: true
      }
      MasterfilesApp::PmCompositionLevel.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::PmCompositionLevel.call(:create)
      assert res.success, 'Should always be able to create a pm_composition_level'
    end

    def test_edit
      MasterfilesApp::BomsRepo.any_instance.stubs(:find_pm_composition_level).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PmCompositionLevel.call(:edit, 1)
      assert res.success, 'Should be able to edit a pm_composition_level'
    end

    def test_delete
      MasterfilesApp::BomsRepo.any_instance.stubs(:find_pm_composition_level).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PmCompositionLevel.call(:delete, 1)
      assert res.success, 'Should be able to delete a pm_composition_level'
    end
  end
end
