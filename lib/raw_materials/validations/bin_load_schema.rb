# frozen_string_literal: true

module RawMaterialsApp
  BinLoadSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:bin_load_purpose_id, :integer).maybe(:int?)
    required(:customer_party_role_id, :integer).filled(:int?)
    required(:transporter_party_role_id, :integer).maybe(:int?)
    required(:dest_depot_id, :integer).filled(:int?)
    required(:qty_bins, :integer).filled(:int?)
    optional(:shipped_at, %i[nil time]).maybe(:time?)
    optional(:shipped, :bool).maybe(:bool?)
    optional(:completed_at, %i[nil time]).maybe(:time?)
    optional(:completed, :bool).maybe(:bool?)
  end
end
