# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestGovtInspectionSheetPermission < Minitest::Test
    include Crossbeams::Responses
    include GovtInspectionFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        inspector_id: 1,
        inspection_billing_party_role_id: 1,
        exporter_party_role_id: 1,
        booking_reference: Faker::Lorem.unique.word,
        results_captured: false,
        results_captured_at: '2010-01-01 12:00',
        api_results_received: false,
        completed: false,
        completed_at: '2010-01-01 12:00',
        inspected: false,
        inspection_point: 'ABC',
        awaiting_inspection_results: false,
        destination_country_id: 1,
        govt_inspection_api_result_id: 1,
        active: true
      }
      FinishedGoodsApp::GovtInspectionSheet.new(base_attrs.merge(attrs))
    end

    def test_create
      res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionSheet.call(:create)
      assert res.success, 'Should always be able to create a govt_inspection_sheet'
    end

    def test_edit
      FinishedGoodsApp::GovtInspectionSheetRepo.any_instance.stubs(:find_govt_inspection_sheet).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionSheet.call(:edit, 1)
      assert res.success, 'Should be able to edit a govt_inspection_sheet'

      # FinishedGoodsApp::GovtInspectionSheetRepo.any_instance.stubs(:find_govt_inspection_sheet).returns(entity(completed: true))
      # res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionSheet.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed govt_inspection_sheet'
    end

    def test_delete
      FinishedGoodsApp::GovtInspectionSheetRepo.any_instance.stubs(:find_govt_inspection_sheet).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionSheet.call(:delete, 1)
      assert res.success, 'Should be able to delete a govt_inspection_sheet'

      # FinishedGoodsApp::GovtInspectionSheetRepo.any_instance.stubs(:find_govt_inspection_sheet).returns(entity(completed: true))
      # res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionSheet.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed govt_inspection_sheet'
    end

    # def test_complete
    #   FinishedGoodsApp::GovtInspectionSheetRepo.any_instance.stubs(:find_govt_inspection_sheet).returns(entity)
    #   res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionSheet.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a govt_inspection_sheet'

    #   FinishedGoodsApp::GovtInspectionSheetRepo.any_instance.stubs(:find_govt_inspection_sheet).returns(entity(completed: true))
    #   res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionSheet.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed govt_inspection_sheet'
    # end

    # def test_approve
    #   FinishedGoodsApp::GovtInspectionSheetRepo.any_instance.stubs(:find_govt_inspection_sheet).returns(entity(completed: true, approved: false))
    #   res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionSheet.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed govt_inspection_sheet'

    #   FinishedGoodsApp::GovtInspectionSheetRepo.any_instance.stubs(:find_govt_inspection_sheet).returns(entity)
    #   res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionSheet.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed govt_inspection_sheet'

    #   FinishedGoodsApp::GovtInspectionSheetRepo.any_instance.stubs(:find_govt_inspection_sheet).returns(entity(completed: true, approved: true))
    #   res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionSheet.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved govt_inspection_sheet'
    # end

    # def test_reopen
    #   FinishedGoodsApp::GovtInspectionSheetRepo.any_instance.stubs(:find_govt_inspection_sheet).returns(entity)
    #   res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionSheet.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a govt_inspection_sheet that has not been approved'

    #   FinishedGoodsApp::GovtInspectionSheetRepo.any_instance.stubs(:find_govt_inspection_sheet).returns(entity(completed: true, approved: true))
    #   res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionSheet.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved govt_inspection_sheet'
    # end
  end
end
