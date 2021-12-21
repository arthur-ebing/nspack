# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestFruitDefectPermission < Minitest::Test
    include Crossbeams::Responses
    include QcFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        fruit_defect_type_id: 1,
        fruit_defect_code: Faker::Lorem.unique.word,
        short_description: 'ABC',
        description: 'ABC',
        reporting_description: 'ABC',
        internal: false,
        external: false,
        pre_harvest: false,
        post_harvest: false,
        severity: 'ABC',
        qc_class_2: false,
        qc_class_3: false,
        active: true
      }
      MasterfilesApp::FruitDefect.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::FruitDefect.call(:create)
      assert res.success, 'Should always be able to create a fruit_defect'
    end

    def test_edit
      MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::FruitDefect.call(:edit, 1)
      assert res.success, 'Should be able to edit a fruit_defect'

      # MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::FruitDefect.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed fruit_defect'
    end

    def test_delete
      MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::FruitDefect.call(:delete, 1)
      assert res.success, 'Should be able to delete a fruit_defect'

      # MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::FruitDefect.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed fruit_defect'
    end

    # def test_complete
    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::FruitDefect.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a fruit_defect'

    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect).returns(entity(completed: true))
    #   res = MasterfilesApp::TaskPermissionCheck::FruitDefect.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed fruit_defect'
    # end

    # def test_approve
    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect).returns(entity(completed: true, approved: false))
    #   res = MasterfilesApp::TaskPermissionCheck::FruitDefect.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed fruit_defect'

    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::FruitDefect.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed fruit_defect'

    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::FruitDefect.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved fruit_defect'
    # end

    # def test_reopen
    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::FruitDefect.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a fruit_defect that has not been approved'

    #   MasterfilesApp::QcRepo.any_instance.stubs(:find_fruit_defect).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::FruitDefect.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved fruit_defect'
    # end
  end
end
