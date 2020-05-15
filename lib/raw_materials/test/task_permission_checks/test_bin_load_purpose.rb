# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module RawMaterialsApp
  class TestBinLoadPurposePermission < Minitest::Test
    include Crossbeams::Responses
    include BinLoadFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        purpose_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
      RawMaterialsApp::BinLoadPurpose.new(base_attrs.merge(attrs))
    end

    def test_create
      res = RawMaterialsApp::TaskPermissionCheck::BinLoadPurpose.call(:create)
      assert res.success, 'Should always be able to create a bin_load_purpose'
    end

    def test_edit
      RawMaterialsApp::BinLoadRepo.any_instance.stubs(:find_bin_load_purpose).returns(entity)
      res = RawMaterialsApp::TaskPermissionCheck::BinLoadPurpose.call(:edit, 1)
      assert res.success, 'Should be able to edit a bin_load_purpose'

      # RawMaterialsApp::BinLoadRepo.any_instance.stubs(:find_bin_load_purpose).returns(entity(completed: true))
      # res = RawMaterialsApp::TaskPermissionCheck::BinLoadPurpose.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed bin_load_purpose'
    end

    def test_delete
      RawMaterialsApp::BinLoadRepo.any_instance.stubs(:find_bin_load_purpose).returns(entity)
      res = RawMaterialsApp::TaskPermissionCheck::BinLoadPurpose.call(:delete, 1)
      assert res.success, 'Should be able to delete a bin_load_purpose'

      # RawMaterialsApp::BinLoadRepo.any_instance.stubs(:find_bin_load_purpose).returns(entity(completed: true))
      # res = RawMaterialsApp::TaskPermissionCheck::BinLoadPurpose.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed bin_load_purpose'
    end

    # def test_complete
    #   RawMaterialsApp::BinLoadRepo.any_instance.stubs(:find_bin_load_purpose).returns(entity)
    #   res = RawMaterialsApp::TaskPermissionCheck::BinLoadPurpose.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a bin_load_purpose'

    #   RawMaterialsApp::BinLoadRepo.any_instance.stubs(:find_bin_load_purpose).returns(entity(completed: true))
    #   res = RawMaterialsApp::TaskPermissionCheck::BinLoadPurpose.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed bin_load_purpose'
    # end

    # def test_approve
    #   RawMaterialsApp::BinLoadRepo.any_instance.stubs(:find_bin_load_purpose).returns(entity(completed: true, approved: false))
    #   res = RawMaterialsApp::TaskPermissionCheck::BinLoadPurpose.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed bin_load_purpose'

    #   RawMaterialsApp::BinLoadRepo.any_instance.stubs(:find_bin_load_purpose).returns(entity)
    #   res = RawMaterialsApp::TaskPermissionCheck::BinLoadPurpose.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed bin_load_purpose'

    #   RawMaterialsApp::BinLoadRepo.any_instance.stubs(:find_bin_load_purpose).returns(entity(completed: true, approved: true))
    #   res = RawMaterialsApp::TaskPermissionCheck::BinLoadPurpose.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved bin_load_purpose'
    # end

    # def test_reopen
    #   RawMaterialsApp::BinLoadRepo.any_instance.stubs(:find_bin_load_purpose).returns(entity)
    #   res = RawMaterialsApp::TaskPermissionCheck::BinLoadPurpose.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a bin_load_purpose that has not been approved'

    #   RawMaterialsApp::BinLoadRepo.any_instance.stubs(:find_bin_load_purpose).returns(entity(completed: true, approved: true))
    #   res = RawMaterialsApp::TaskPermissionCheck::BinLoadPurpose.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved bin_load_purpose'
    # end
  end
end
