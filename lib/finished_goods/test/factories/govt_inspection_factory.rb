# frozen_string_literal: true

module FinishedGoodsApp
  module GovtInspectionFactory
    def create_inspector(opts = {})
      party_role_id = create_party_role[:id]

      default = {
        inspector_party_role_id: party_role_id,
        inspector_code: Faker::Lorem.unique.word,
        tablet_ip_address: Faker::Lorem.unique.word,
        tablet_port_number: Faker::Number.number(4),
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:inspectors].insert(default.merge(opts))
    end

    def create_govt_inspection_sheet(opts = {})
      inspector_id = create_inspector
      destination_country_id = create_destination_country
      party_role_id = create_party_role[:id]

      default = {
        inspector_id: inspector_id,
        inspection_billing_party_role_id: party_role_id,
        exporter_party_role_id: party_role_id,
        booking_reference: Faker::Lorem.unique.word,
        results_captured: false,
        results_captured_at: '2010-01-01 12:00',
        api_results_received: false,
        completed: false,
        completed_at: '2010-01-01 12:00',
        inspected: false,
        inspection_point: Faker::Lorem.word,
        awaiting_inspection_results: false,
        destination_country_id: destination_country_id,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        govt_inspection_api_result_id: nil
      }
      DB[:govt_inspection_sheets].insert(default.merge(opts))
    end

    def create_govt_inspection_pallet(opts = {})
      pallet_id = create_pallet
      govt_inspection_sheet_id = create_govt_inspection_sheet
      failure_reason_id = create_inspection_failure_reason

      default = {
        pallet_id: pallet_id,
        govt_inspection_sheet_id: govt_inspection_sheet_id,
        passed: false,
        inspected: false,
        inspected_at: '2010-01-01 12:00',
        failure_reason_id: failure_reason_id,
        failure_remarks: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:govt_inspection_pallets].insert(default.merge(opts))
    end

    def create_govt_inspection_api_result(opts = {})
      govt_inspection_sheet_id = create_govt_inspection_sheet

      default = {
        govt_inspection_sheet_id: govt_inspection_sheet_id,
        govt_inspection_request_doc: {},
        govt_inspection_result_doc: {},
        results_requested: false,
        results_requested_at: '2010-01-01 12:00',
        results_received: false,
        results_received_at: '2010-01-01 12:00',
        upn_number: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      default.merge(opts)

      DB[:govt_inspection_api_results].insert(default.merge(opts))
    end

    def create_govt_inspection_pallet_api_result(opts = {})
      govt_inspection_pallet_id = create_govt_inspection_pallet

      default = {
        passed: false,
        failure_reasons: {},
        govt_inspection_pallet_id: govt_inspection_pallet_id,
        govt_inspection_api_result_id: govt_inspection_api_result_id,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:govt_inspection_pallet_api_results].insert(default.merge(opts))
    end
  end
end
