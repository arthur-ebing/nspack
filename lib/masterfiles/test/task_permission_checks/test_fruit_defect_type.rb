# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestFruitDefectTypePermission < Minitest::Test
    include Crossbeams::Responses
    include QcFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        fruit_defect_category_id: 1,
        fruit_defect_type_name: Faker::Lorem.unique.word,
        description: 'ABC',
        reporting_description: 'ABC',
        active: true
      }
      MasterfilesApp::FruitDefectType.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::FruitDefectType.call(:create)
      assert res.success, 'Should always be able to create a fruit_defect_type'
    end

    def test_edit
      MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::FruitDefectType.call(:edit, 1)
      assert res.success, 'Should be able to edit a fruit_defect_type'

      # MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_type).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::FruitDefectType.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed fruit_defect_type'
    end

    def test_delete
      MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::FruitDefectType.call(:delete, 1)
      assert res.success, 'Should be able to delete a fruit_defect_type'

      # MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_type).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::FruitDefectType.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed fruit_defect_type'
    end

    # def test_complete
    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_type).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::FruitDefectType.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a fruit_defect_type'

    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_type).returns(entity(completed: true))
    #   res = MasterfilesApp::TaskPermissionCheck::FruitDefectType.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed fruit_defect_type'
    # end

    # def test_approve
    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_type).returns(entity(completed: true, approved: false))
    #   res = MasterfilesApp::TaskPermissionCheck::FruitDefectType.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed fruit_defect_type'

    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_type).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::FruitDefectType.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed fruit_defect_type'

    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_type).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::FruitDefectType.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved fruit_defect_type'
    # end

    # def test_reopen
    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_type).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::FruitDefectType.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a fruit_defect_type that has not been approved'

    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_type).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::FruitDefectType.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved fruit_defect_type'
    # end
  end
end
