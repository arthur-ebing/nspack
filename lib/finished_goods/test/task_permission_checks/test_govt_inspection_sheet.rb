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
        tripsheet_created_at: '2010-01-01 12:00',
        tripsheet_loaded_at: '2010-01-01 12:00',
        inspected: false,
        inspection_point: 'ABC',
        awaiting_inspection_results: false,
        packed_tm_group_id: 1,
        destination_region_id: 1,
        govt_inspection_api_result_id: 1,
        reinspection: false,
        created_by: 1,
        consignment_note_number: '00000001',
        active: true
      }
      FinishedGoodsApp::GovtInspectionSheet.new(base_attrs.merge(attrs))
    end

    def test_create
      res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionSheet.call(:create)
      assert res.success, 'Should always be able to create a govt_inspection_sheet'
    end

    def test_edit
      FinishedGoodsApp::GovtInspectionRepo.any_instance.stubs(:find_govt_inspection_sheet).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionSheet.call(:edit, 1)
      assert res.success, 'Should be able to edit a govt_inspection_sheet'
    end

    def test_delete
      FinishedGoodsApp::GovtInspectionRepo.any_instance.stubs(:find_govt_inspection_sheet).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::GovtInspectionSheet.call(:delete, 1)
      assert res.success, 'Should be able to delete a govt_inspection_sheet'
    end
  end
end
