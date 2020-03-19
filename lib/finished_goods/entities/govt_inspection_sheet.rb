# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionSheet < Dry::Struct
    attribute :id, Types::Integer
    attribute :inspector_id, Types::Integer
    attribute :inspection_billing_party_role_id, Types::Integer
    attribute :exporter_party_role_id, Types::Integer
    attribute :booking_reference, Types::String
    attribute :results_captured, Types::Bool
    attribute :results_captured_at, Types::DateTime
    attribute :api_results_received, Types::Bool
    attribute :completed, Types::Bool
    attribute :completed_at, Types::DateTime
    attribute :inspected, Types::Bool
    attribute :inspection_point, Types::String
    attribute :awaiting_inspection_results, Types::Bool
    attribute :destination_country_id, Types::Integer
    attribute :govt_inspection_api_result_id, Types::Integer
    attribute :reinspection, Types::Bool
    attribute :created_by, Types::String
    attribute? :active, Types::Bool
  end
end
