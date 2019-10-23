# frozen_string_literal: true

module MesscadaApp
  PalletSchema = Dry::Validation.Params do # rubocop:disable Metrics/BlockLength
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    optional(:pallet_number, Types::StrippedString).filled(:str?)
    optional(:exit_ref, Types::StrippedString).maybe(:str?)
    optional(:scrapped_at, %i[nil time]).maybe(:time?)
    required(:location_id, :integer).filled(:int?)
    optional(:shipped, :bool).maybe(:bool?)
    optional(:in_stock, :bool).maybe(:bool?)
    optional(:inspected, :bool).maybe(:bool?)
    optional(:shipped_at, %i[nil time]).maybe(:time?)
    optional(:govt_first_inspection_at, %i[nil time]).maybe(:time?)
    optional(:govt_reinspection_at, %i[nil time]).maybe(:time?)
    optional(:internal_inspection_at, %i[nil time]).maybe(:time?)
    optional(:internal_reinspection_at, %i[nil time]).maybe(:time?)
    optional(:stock_created_at, %i[nil time]).maybe(:time?)
    required(:phc, Types::StrippedString).filled(:str?)
    optional(:intake_created_at, %i[nil time]).maybe(:time?)
    optional(:first_cold_storage_at, %i[nil time]).maybe(:time?)
    optional(:build_status, Types::StrippedString).maybe(:str?)
    optional(:gross_weight, %i[nil decimal]).maybe(:decimal?)
    optional(:gross_weight_measured_at, %i[nil time]).maybe(:time?)
    optional(:palletized, :bool).maybe(:bool?)
    optional(:partially_palletized, :bool).maybe(:bool?)
    optional(:palletized_at, %i[nil time]).maybe(:time?)
    optional(:partially_palletized_at, %i[nil time]).maybe(:time?)
    required(:fruit_sticker_pm_product_id, :integer).maybe(:int?)
    optional(:allocated, :bool).maybe(:bool?)
    optional(:allocated_at, %i[nil time]).maybe(:time?)
    optional(:reinspected, :bool).maybe(:bool?)
    optional(:scrapped, :bool).maybe(:bool?)
    required(:pallet_format_id, :integer).filled(:int?)
    optional(:carton_quantity, :integer).maybe(:int?)
    optional(:govt_inspection_passed, :bool).maybe(:bool?)
    optional(:internal_inspection_passed, :bool).maybe(:bool?)
    required(:plt_packhouse_resource_id, :integer).maybe(:int?)
    required(:plt_line_resource_id, :integer).maybe(:int?)
    optional(:nett_weight, %i[nil decimal]).maybe(:decimal?)
    optional(:load_id, :integer).maybe(:int?)
    optional(:cooled, :bool).maybe(:bool?)
  end
end
