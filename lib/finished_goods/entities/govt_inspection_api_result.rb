# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionApiResult < Dry::Struct
    attribute :id, Types::Integer
    attribute :govt_inspection_sheet_id, Types::Integer
    attribute :govt_inspection_request_doc, Types::Hash
    attribute :govt_inspection_result_doc, Types::Hash
    attribute :results_requested, Types::Bool
    attribute :results_requested_at, Types::DateTime
    attribute :results_received, Types::Bool
    attribute :results_received_at, Types::DateTime
    attribute :upn_number, Types::String
    attribute? :active, Types::Bool
  end
end
