# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestGovtInspectionSheetPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        inspector_id: 1,
        inspector: Faker::Lorem.unique.word,
        inspection_billing_party_role_id: 1,
        inspection_billing: Faker::Lorem.unique.word,
        exporter_party_role_id: 1,
        exporter: Faker::Lorem.unique.word,
        booking_reference: Faker::Lorem.unique.word,
        results_captured: false,
        results_captured_at: '2010-01-01 12:00',
        api_results_received: false,
        allocated: false,
        passed_pallets: false,
        failed_pallets: false,
        completed: false,
        completed_at: '2010-01-01 12:00',
        cancelled: false,
        cancelled_at: '2010-01-01 12:00',
        inspected: false,
        inspector_code: nil,
        inspection_point: Faker::Lorem.unique.word,
        awaiting_inspection_results: false,
        packed_tm_group_id: 1,
        packed_tm_group: Faker::Lorem.unique.word,
        destination_region_id: 1,
        destination_region: Faker::Lorem.unique.word,
        destination_country_id: 1,
        destination_country: Faker::Lorem.unique.word,
        iso_country_code: Faker::Lorem.unique.word,
        reinspection: false,
        allow_titan_inspection: false,
        upn: '123',
        created_by: Faker::Lorem.unique.word,
        consignment_note_number: Faker::Lorem.unique.word,
        tripsheet_created: false,
        tripsheet_created_at: '2010-01-01 12:00',
        tripsheet_loaded: false,
        tripsheet_loaded_at: '2010-01-01 12:00',
        tripsheet_offloaded: false,
        use_inspection_destination_for_load_out: false,
        active: true,
        titan_protocol_exception: 'ABC'
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
