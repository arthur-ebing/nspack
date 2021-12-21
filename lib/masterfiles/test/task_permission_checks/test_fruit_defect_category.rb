# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestFruitDefectCategoryPermission < Minitest::Test
    include Crossbeams::Responses
    include QcFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        defect_category: Faker::Lorem.unique.word,
        reporting_description: 'ABC',
        active: true
      }
      MasterfilesApp::FruitDefectCategory.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::FruitDefectCategory.call(:create)
      assert res.success, 'Should always be able to create a fruit_defect_category'
    end

    def test_edit
      MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_category).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::FruitDefectCategory.call(:edit, 1)
      assert res.success, 'Should be able to edit a fruit_defect_category'

      # MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_category).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::FruitDefectCategory.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed fruit_defect_category'
    end

    def test_delete
      MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_category).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::FruitDefectCategory.call(:delete, 1)
      assert res.success, 'Should be able to delete a fruit_defect_category'

      # MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_category).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::FruitDefectCategory.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed fruit_defect_category'
    end

    # def test_complete
    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_category).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::FruitDefectCategory.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a fruit_defect_category'

    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_category).returns(entity(completed: true))
    #   res = MasterfilesApp::TaskPermissionCheck::FruitDefectCategory.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed fruit_defect_category'
    # end

    # def test_approve
    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_category).returns(entity(completed: true, approved: false))
    #   res = MasterfilesApp::TaskPermissionCheck::FruitDefectCategory.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed fruit_defect_category'

    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_category).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::FruitDefectCategory.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed fruit_defect_category'

    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_category).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::FruitDefectCategory.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved fruit_defect_category'
    # end

    # def test_reopen
    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_category).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::FruitDefectCategory.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a fruit_defect_category that has not been approved'

    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect_category).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::FruitDefectCategory.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved fruit_defect_category'
    # end
  end
end
