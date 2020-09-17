# frozen_string_literal: true

module FinishedGoodsApp
  GovtInspectionSheetSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:inspector_id).filled(:integer)
    required(:inspection_billing_party_role_id).filled(:integer)
    required(:exporter_party_role_id).filled(:integer)
    required(:booking_reference).filled(Types::StrippedString)
    optional(:results_captured).maybe(:bool)
    optional(:results_captured_at).maybe(:time)
    optional(:api_results_received).maybe(:bool)
    optional(:completed).maybe(:bool)
    optional(:completed_at).maybe(:time)
    optional(:inspected).maybe(:bool)
    required(:inspection_point).maybe(Types::StrippedString)
    optional(:awaiting_inspection_results).maybe(:bool)
    required(:packed_tm_group_id).filled(:integer)
    required(:destination_region_id).filled(:integer)
    optional(:govt_inspection_api_result_id).maybe(:integer)
    optional(:reinspection).maybe(:bool)
    optional(:tripsheet_created).maybe(:bool)
    optional(:tripsheet_created_at).maybe(:time)
    optional(:tripsheet_loaded).maybe(:bool)
    optional(:tripsheet_loaded_at).maybe(:time)
    optional(:tripsheet_offloaded).maybe(:bool)
    optional(:use_inspection_destination_for_load_out).maybe(:bool)
    optional(:created_by).maybe(Types::StrippedString)
  end
end
