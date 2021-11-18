# frozen_string_literal: true

module FinishedGoodsApp
  LoadServiceSchema = Dry::Schema.Params do # rubocop:disable Metrics/BlockLength
    optional(:id).filled(:integer)
    optional(:load_id).filled(:integer)
    optional(:rmt_load).maybe(:bool)
    required(:customer_party_role_id).filled(:integer)
    required(:exporter_party_role_id).filled(:integer)
    required(:billing_client_party_role_id).filled(:integer)
    required(:consignee_party_role_id).filled(:integer)
    required(:final_receiver_party_role_id).filled(:integer)
    optional(:order_id).maybe(:integer)
    optional(:order_number).maybe(Types::StrippedString)
    optional(:customer_order_number).maybe(Types::StrippedString)
    optional(:customer_reference).maybe(Types::StrippedString)
    required(:depot_id).filled(:integer)
    optional(:exporter_certificate_code).maybe(Types::StrippedString)
    required(:voyage_type_id).filled(:integer)
    required(:vessel_id).filled(:integer)
    required(:voyage_number).filled(Types::StrippedString)
    required(:year).filled(:integer)
    required(:pol_port_id).filled(:integer)
    required(:pod_port_id).filled(:integer)
    required(:final_destination_id).filled(:integer)
    optional(:shipped_at).maybe(:time)
    optional(:shipped).maybe(:bool)
    required(:requires_temp_tail).filled(:bool)
    required(:transfer_load).maybe(:bool)
    optional(:shipping_line_party_role_id).maybe(:integer)
    optional(:shipper_party_role_id).maybe(:integer)
    optional(:booking_reference).maybe(Types::StrippedString)
    optional(:memo_pad).maybe(Types::StrippedString)
    optional(:location_of_issue).maybe(Types::StrippedString)
    optional(:truck_must_be_weighed).maybe(:bool)
  end

  LoadSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:customer_party_role_id).filled(:integer)
    required(:consignee_party_role_id).filled(:integer)
    required(:billing_client_party_role_id).filled(:integer)
    required(:exporter_party_role_id).filled(:integer)
    required(:final_receiver_party_role_id).maybe(:integer)
    required(:final_destination_id).filled(:integer)
    required(:depot_id).filled(:integer)
    required(:pol_voyage_port_id).filled(:integer)
    required(:pod_voyage_port_id).filled(:integer)
    optional(:edi_file_name).maybe(Types::StrippedString)
    optional(:customer_order_number).maybe(Types::StrippedString)
    optional(:customer_reference).maybe(Types::StrippedString)
    optional(:exporter_certificate_code).maybe(Types::StrippedString)
    optional(:shipped_at).maybe(:time)
    optional(:shipped).maybe(:bool)
    required(:transfer_load).maybe(:bool)
    optional(:order_number).maybe(Types::StrippedString)
    optional(:allocated).maybe(:bool)
    optional(:rmt_load).maybe(:bool)
    optional(:allocated_at).maybe(:time)
    required(:requires_temp_tail).filled(:bool)
    optional(:location_of_issue).maybe(Types::StrippedString)
    optional(:truck_must_be_weighed).maybe(:bool)
  end

  LoadEditShippedDateSchema = Dry::Schema.Params do
    required(:shipped_at).filled(:time)
    required(:load_shipped_at).filled(:time)
  end

  LoadContainerWeightSchema = Dry::Schema.Params do
    required(:max_gross_weight).maybe(:decimal)
    required(:max_payload).maybe(:decimal)
    required(:tare_weight).filled(:decimal)
    required(:actual_payload).filled(:decimal)
  end
end
