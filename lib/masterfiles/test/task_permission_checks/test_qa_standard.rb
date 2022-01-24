# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestQaStandardPermission < Minitest::Test
    include Crossbeams::Responses
    include QaStandardFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        qa_standard_name: Faker::Lorem.unique.word,
        description: 'ABC',
        season_id: 1,
        qa_standard_type_id: 1,
        target_market_ids: [1, 2, 3],
        packed_tm_group_ids: [1, 2, 3],
        internal_standard: false,
        applies_to_all_markets: false,
        active: true
      }
      MasterfilesApp::QaStandard.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::QaStandard.call(:create)
      assert res.success, 'Should always be able to create a qa_standard'
    end

    def test_edit
      MasterfilesApp::QaStandardRepo.any_instance.stubs(:find_qa_standard).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::QaStandard.call(:edit, 1)
      assert res.success, 'Should be able to edit a qa_standard'

      # MasterfilesApp::QaStandardRepo.any_instance.stubs(:find_qa_standard).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::QaStandard.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed qa_standard'
    end

    def test_delete
      MasterfilesApp::QaStandardRepo.any_instance.stubs(:find_qa_standard).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::QaStandard.call(:delete, 1)
      assert res.success, 'Should be able to delete a qa_standard'

      # MasterfilesApp::QaStandardRepo.any_instance.stubs(:find_qa_standard).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::QaStandard.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed qa_standard'
    end

    # def test_complete
    #   MasterfilesApp::QaStandardRepo.any_instance.stubs(:find_qa_standard).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::QaStandard.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a qa_standard'

    #   MasterfilesApp::QaStandardRepo.any_instance.stubs(:find_qa_standard).returns(entity(completed: true))
    #   res = MasterfilesApp::TaskPermissionCheck::QaStandard.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed qa_standard'
    # end

    # def test_approve
    #   MasterfilesApp::QaStandardRepo.any_instance.stubs(:find_qa_standard).returns(entity(completed: true, approved: false))
    #   res = MasterfilesApp::TaskPermissionCheck::QaStandard.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed qa_standard'

    #   MasterfilesApp::QaStandardRepo.any_instance.stubs(:find_qa_standard).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::QaStandard.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed qa_standard'

    #   MasterfilesApp::QaStandardRepo.any_instance.stubs(:find_qa_standard).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::QaStandard.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved qa_standard'
    # end

    # def test_reopen
    #   MasterfilesApp::QaStandardRepo.any_instance.stubs(:find_qa_standard).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::QaStandard.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a qa_standard that has not been approved'

    #   MasterfilesApp::QaStandardRepo.any_instance.stubs(:find_qa_standard).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::QaStandard.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved qa_standard'
    # end
  end
end
