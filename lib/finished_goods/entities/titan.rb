# frozen_string_literal: true

module FinishedGoodsApp
  class TitanRequest < Dry::Struct
    attribute :id, Types::Integer
    attribute :load_id, Types::Integer
    attribute :govt_inspection_sheet_id, Types::Integer
    attribute :request_type, Types::String
    attribute :request_doc, Types::Hash
    attribute :success, Types::Bool
    attribute :result_doc, Types::Hash
    attribute :inspection_message_id, Types::Integer
    attribute :transaction_id, Types::Integer
    attribute :request_id, Types::String
    attribute :created_at, Types::DateTime
  end

  class TitanRequestFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :load_id, Types::Integer
    attribute :govt_inspection_sheet_id, Types::Integer
    attribute :request_type, Types::String
    attribute :request_doc, Types::Hash
    attribute :result_doc, Types::Hash
    attribute :request_array, Types::Array
    attribute :result_array, Types::Array

    attribute :transaction_id, Types::Integer
    attribute :inspection_message_id, Types::Integer
    attribute :request_id, Types::String
    attribute :created_at, Types::DateTime
  end

  class TitanInspectionFlat < Dry::Struct
    attribute :govt_inspection_sheet_id, Types::Integer
    attribute :inspection_message_id, Types::Integer
    attribute :request_type, Types::String
    attribute :success, Types::String
    attribute :upn, Types::String
    attribute :titan_inspector, Types::String
    attribute :pallets, Types::Array
    attribute :reinspection, Types::Bool
    attribute :validated, Types::Bool
  end

  class TitanAddendumFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :load_id, Types::Integer
    attribute :request_id, Types::String
    attribute :transaction_id, Types::Integer
    attribute :updated_at, Types::DateTime

    attribute :addendum_status, Types::String
    # attribute :best_regime_code, Types::String
    attribute :verification_status, Types::String
    attribute :addendum_validations, Types::String
    # attribute :available_regime_code, Types::String
    attribute :e_cert_response_message, Types::String
    attribute :e_cert_hub_tracking_number, Types::String
    attribute :e_cert_hub_tracking_status, Types::String
    # attribute :e_cert_application_status, Types::String
    # attribute :phyt_clean_verification_key, Types::String
    attribute :export_certification_status, Types::String

    attribute :cancelled_status, Types::String
    attribute :cancelled_at, Types::DateTime
    attribute :request_doc, Types::String
    attribute :result_doc, Types::String
  end
end
