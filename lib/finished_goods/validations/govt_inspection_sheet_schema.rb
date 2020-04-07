# frozen_string_literal: true

module FinishedGoodsApp
  GovtInspectionSheetSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:inspector_id, :integer).filled(:int?)
    required(:inspection_billing_party_role_id, :integer).filled(:int?)
    required(:exporter_party_role_id, :integer).filled(:int?)
    required(:booking_reference, Types::StrippedString).filled(:str?)
    optional(:results_captured, :bool).maybe(:bool?)
    optional(:results_captured_at, %i[nil time]).maybe(:time?)
    optional(:api_results_received, :bool).maybe(:bool?)
    optional(:completed, :bool).maybe(:bool?)
    optional(:completed_at, %i[nil time]).maybe(:time?)
    optional(:inspected, :bool).maybe(:bool?)
    required(:inspection_point, Types::StrippedString).maybe(:str?)
    optional(:awaiting_inspection_results, :bool).maybe(:bool?)
    required(:packed_tm_group_id, :integer).filled(:int?)
    required(:destination_region_id, :integer).filled(:int?)
    optional(:govt_inspection_api_result_id, :integer).maybe(:int?)
    optional(:reinspection, :bool).maybe(:bool?)
    optional(:tripsheet_created, :bool).maybe(:bool?)
    optional(:tripsheet_created_at, %i[nil time]).maybe(:time?)
    optional(:tripsheet_loaded, :bool).maybe(:bool?)
    optional(:tripsheet_loaded_at, %i[nil time]).maybe(:time?)
    optional(:tripsheet_offloaded, :bool).maybe(:bool?)
    optional(:created_by, Types::StrippedString).maybe(:str?)
  end
end
