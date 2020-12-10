# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestInspectionTypePermission < Minitest::Test
    include Crossbeams::Responses
    include InspectionFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        inspection_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        inspection_failure_type_id: 1,
        applies_to_all_tm_groups: false,
        applicable_tm_group_ids: [1, 2, 3],
        applies_to_all_cultivars: false,
        applicable_cultivar_ids: [1, 2, 3],
        applies_to_all_orchards: false,
        applicable_orchard_ids: [1, 2, 3],
        active: true
      }
      MasterfilesApp::InspectionType.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::InspectionType.call(:create)
      assert res.success, 'Should always be able to create a inspection_type'
    end

    def test_edit
      MasterfilesApp::QualityRepo.any_instance.stubs(:find_inspection_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::InspectionType.call(:edit, 1)
      assert res.success, 'Should be able to edit a inspection_type'
    end

    def test_delete
      MasterfilesApp::QualityRepo.any_instance.stubs(:find_inspection_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::InspectionType.call(:delete, 1)
      assert res.success, 'Should be able to delete a inspection_type'
    end
  end
end
