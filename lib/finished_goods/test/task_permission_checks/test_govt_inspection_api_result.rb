# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestGovtInspectionApiResultPermission < Minitest::Test
    include Crossbeams::Responses
    include GovtInspectionFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        govt_inspection_sheet_id: 1,
        govt_inspection_request_doc: {},
        govt_inspection_result_doc: {},
        results_requested: false,
        results_requested_at: '2010-01-01 12:00',
        results_received: false,
        results_received_at: '2010-01-01 12:00',
        upn_number: Faker::Lorem.unique.word,
        active: true
      }
      FinishedGoodsApp::GovtInspectionApiResult.new(base_attrs.merge(attrs))
    end

    def test_create
      res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionApiResult.call(:create)
      assert res.success, 'Should always be able to create a govt_inspection_api_result'
    end

    def test_edit
      FinishedGoodsApp::GovtInspectionApiResultRepo.any_instance.stubs(:find_govt_inspection_api_result).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionApiResult.call(:edit, 1)
      assert res.success, 'Should be able to edit a govt_inspection_api_result'

      # FinishedGoodsApp::GovtInspectionApiResultRepo.any_instance.stubs(:find_govt_inspection_api_result).returns(entity(completed: true))
      # res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionApiResult.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed govt_inspection_api_result'
    end

    def test_delete
      FinishedGoodsApp::GovtInspectionApiResultRepo.any_instance.stubs(:find_govt_inspection_api_result).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionApiResult.call(:delete, 1)
      assert res.success, 'Should be able to delete a govt_inspection_api_result'

      # FinishedGoodsApp::GovtInspectionApiResultRepo.any_instance.stubs(:find_govt_inspection_api_result).returns(entity(completed: true))
      # res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionApiResult.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed govt_inspection_api_result'
    end

    # def test_complete
    #   FinishedGoodsApp::GovtInspectionApiResultRepo.any_instance.stubs(:find_govt_inspection_api_result).returns(entity)
    #   res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionApiResult.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a govt_inspection_api_result'

    #   FinishedGoodsApp::GovtInspectionApiResultRepo.any_instance.stubs(:find_govt_inspection_api_result).returns(entity(completed: true))
    #   res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionApiResult.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed govt_inspection_api_result'
    # end

    # def test_approve
    #   FinishedGoodsApp::GovtInspectionApiResultRepo.any_instance.stubs(:find_govt_inspection_api_result).returns(entity(completed: true, approved: false))
    #   res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionApiResult.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed govt_inspection_api_result'

    #   FinishedGoodsApp::GovtInspectionApiResultRepo.any_instance.stubs(:find_govt_inspection_api_result).returns(entity)
    #   res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionApiResult.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed govt_inspection_api_result'

    #   FinishedGoodsApp::GovtInspectionApiResultRepo.any_instance.stubs(:find_govt_inspection_api_result).returns(entity(completed: true, approved: true))
    #   res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionApiResult.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved govt_inspection_api_result'
    # end

    # def test_reopen
    #   FinishedGoodsApp::GovtInspectionApiResultRepo.any_instance.stubs(:find_govt_inspection_api_result).returns(entity)
    #   res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionApiResult.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a govt_inspection_api_result that has not been approved'

    #   FinishedGoodsApp::GovtInspectionApiResultRepo.any_instance.stubs(:find_govt_inspection_api_result).returns(entity(completed: true, approved: true))
    #   res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionApiResult.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved govt_inspection_api_result'
    # end
  end
end
