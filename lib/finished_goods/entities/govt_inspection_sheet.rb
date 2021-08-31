# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionSheet < Dry::Struct
    attribute :id, Types::Integer
    attribute :consignment_note_number, Types::String
    attribute :inspector_id, Types::Integer
    attribute :inspector_code, Types::String
    attribute :inspector, Types::String
    attribute :inspection_billing_party_role_id, Types::Integer
    attribute :inspection_billing, Types::String
    attribute :exporter_party_role_id, Types::Integer
    attribute :exporter, Types::String
    attribute :booking_reference, Types::String
    attribute :results_captured, Types::Bool
    attribute :results_captured_at, Types::DateTime
    attribute :api_results_received, Types::Bool
    attribute :allocated, Types::Bool
    attribute :passed_pallets, Types::Bool
    attribute :failed_pallets, Types::Bool
    attribute :completed, Types::Bool
    attribute :completed_at, Types::DateTime
    attribute :cancelled, Types::Bool
    attribute :cancelled_at, Types::DateTime
    attribute :inspected, Types::Bool
    attribute :allow_titan_inspection, Types::Bool
    attribute :inspection_point, Types::String
    attribute :awaiting_inspection_results, Types::Bool
    attribute :packed_tm_group_id, Types::Integer
    attribute :packed_tm_group, Types::String
    attribute :destination_region_id, Types::Integer
    attribute :destination_region, Types::String
    attribute :destination_country_id, Types::Integer
    attribute :destination_country, Types::String
    attribute :iso_country_code, Types::String
    attribute :reinspection, Types::Bool
    attribute :created_by, Types::String
    attribute :tripsheet_created, Types::Bool
    attribute :tripsheet_created_at, Types::DateTime
    attribute :tripsheet_loaded, Types::Bool
    attribute :tripsheet_loaded_at, Types::DateTime
    attribute :tripsheet_offloaded, Types::Bool
    attribute :use_inspection_destination_for_load_out, Types::Bool
    attribute :upn, Types::String
    attribute? :status, Types::String
    attribute? :active, Types::Bool
  end
end
