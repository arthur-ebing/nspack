# frozen_string_literal: true

module MesscadaApp
  PalletSchema = Dry::Schema.Params do # rubocop:disable Metrics/BlockLength
    optional(:id).filled(:integer)
    optional(:pallet_number).filled(Types::StrippedString)
    optional(:exit_ref).maybe(Types::StrippedString)
    optional(:scrapped_at).maybe(:time)
    required(:location_id).filled(:integer)
    optional(:shipped).maybe(:bool)
    optional(:in_stock).maybe(:bool)
    optional(:inspected).maybe(:bool)
    optional(:shipped_at).maybe(:time)
    optional(:govt_first_inspection_at).maybe(:time)
    optional(:govt_reinspection_at).maybe(:time)
    optional(:stock_created_at).maybe(:time)
    required(:phc).filled(Types::StrippedString)
    optional(:intake_created_at).maybe(:time)
    optional(:first_cold_storage_at).maybe(:time)
    optional(:build_status).maybe(Types::StrippedString)
    optional(:gross_weight).maybe(:decimal)
    optional(:gross_weight_measured_at).maybe(:time)
    optional(:palletized).maybe(:bool)
    optional(:partially_palletized).maybe(:bool)
    optional(:palletized_at).maybe(:time)
    optional(:partially_palletized_at).maybe(:time)
    required(:fruit_sticker_pm_product_id).maybe(:integer)
    optional(:fruit_sticker_pm_product_2_id).maybe(:integer)
    optional(:allocated).maybe(:bool)
    optional(:allocated_at).maybe(:time)
    optional(:reinspected).maybe(:bool)
    optional(:scrapped).maybe(:bool)
    required(:pallet_format_id).filled(:integer)
    optional(:carton_quantity).maybe(:integer)
    optional(:govt_inspection_passed).maybe(:bool)
    required(:plt_packhouse_resource_id).maybe(:integer)
    required(:plt_line_resource_id).maybe(:integer)
    optional(:nett_weight).maybe(:decimal)
    optional(:load_id).maybe(:integer)
    optional(:cooled).maybe(:bool)
    optional(:palletizing_bay_resource_id).maybe(:integer)
    optional(:has_individual_cartons).maybe(:bool)
  end
end
