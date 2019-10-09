# frozen_string_literal: true

module FinishedGoodsApp
  LoadSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:depot_id, :integer).filled(:int?)
    required(:customer_party_role_id, :integer).filled(:int?)
    required(:consignee_party_role_id, :integer).filled(:int?)
    required(:billing_client_party_role_id, :integer).filled(:int?)
    required(:exporter_party_role_id, :integer).filled(:int?)
    required(:final_receiver_party_role_id, :integer).filled(:int?)
    required(:final_destination_id, :integer).filled(:int?)
    required(:pol_voyage_port_id, :integer).filled(:int?)
    required(:pod_voyage_port_id, :integer).filled(:int?)
    required(:order_number, Types::StrippedString).maybe(:str?)
    required(:edi_file_name, Types::StrippedString).maybe(:str?)
    required(:customer_order_number, Types::StrippedString).maybe(:str?)
    required(:customer_reference, Types::StrippedString).maybe(:str?)
    required(:exporter_certificate_code, Types::StrippedString).maybe(:str?)
    required(:shipped_date, :time).filled(:time?)
    required(:shipped, :bool).maybe(:bool?)
    required(:transfer_load, :bool).maybe(:bool?)
  end
end
