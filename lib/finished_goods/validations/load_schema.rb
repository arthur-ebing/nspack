# frozen_string_literal: true

module FinishedGoodsApp
  LoadSchema = Dry::Validation.Params do # rubocop:disable Metrics/BlockLength
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:customer_party_role_id, :integer).filled(:int?)
    required(:exporter_party_role_id, :integer).filled(:int?)
    required(:billing_client_party_role_id, :integer).filled(:int?)
    required(:consignee_party_role_id, :integer).filled(:int?)
    required(:final_receiver_party_role_id, :integer).filled(:int?)
    required(:order_number, Types::StrippedString).filled(:str?)
    optional(:customer_order_number, Types::StrippedString).maybe(:str?)
    optional(:customer_reference, Types::StrippedString).maybe(:str?)
    required(:depot_id, :integer).filled(:int?)
    optional(:exporter_certificate_code, Types::StrippedString).maybe(:str?)
    required(:voyage_type_id, :integer).filled(:int?)
    required(:vessel_id, :integer).filled(:int?)
    required(:voyage_number, Types::StrippedString).filled(:str?)
    required(:year, :integer).filled(:int?)
    required(:pol_port_id, :integer).filled(:int?)
    required(:pod_port_id, :integer).filled(:int?)
    required(:final_destination_id, :integer).filled(:int?)
    optional(:shipped_date, %i[nil date]).maybe(:date?)
    optional(:shipped, :bool).maybe(:bool?)
    required(:transfer_load, :bool).maybe(:bool?)
    optional(:shipping_line_party_role_id, :integer).maybe(:int?)
    optional(:shipper_party_role_id, :integer).maybe(:int?)
    optional(:booking_reference, Types::StrippedString).maybe(:str?)
    optional(:memo_pad, Types::StrippedString).maybe(:str?)
  end
end
