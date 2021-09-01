# frozen_string_literal: true

module FinishedGoodsApp
  module GovtInspectionFactory
    def create_inspector(opts = {})
      party_role_id = create_party_role(party_type: 'P', name: AppConst::ROLE_INSPECTOR)

      default = {
        inspector_party_role_id: party_role_id,
        inspector_code: Faker::Lorem.unique.word,
        tablet_ip_address: Faker::Lorem.unique.word,
        tablet_port_number: Faker::Number.number(digits: 4),
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:inspectors].insert(default.merge(opts))
    end

    def create_govt_inspection_sheet(opts = {})
      inspector_id = create_inspector
      target_market_group_id = create_target_market_group
      destination_region_id = create_destination_region
      inspection_billing_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_INSPECTION_BILLING)
      exporter_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_EXPORTER)
      target_market_id = create_target_market

      default = {
        inspector_id: inspector_id,
        inspection_billing_party_role_id: inspection_billing_party_role_id,
        exporter_party_role_id: exporter_party_role_id,
        booking_reference: Faker::Lorem.unique.word,
        results_captured: false,
        results_captured_at: '2010-01-01 12:00',
        api_results_received: false,
        completed: false,
        completed_at: '2010-01-01 12:00',
        inspected: false,
        inspection_point: Faker::Lorem.word,
        awaiting_inspection_results: false,
        packed_tm_group_id: target_market_group_id,
        destination_region_id: destination_region_id,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        exception_protocol_tm_id: target_market_id
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
  end
end
