# frozen_string_literal: true

module EdiApp
  class EdiOutTransaction < Dry::Struct
    attribute :id, Types::Integer
    attribute :flow_type, Types::String
    attribute :org_code, Types::String
    attribute :hub_address, Types::String
    attribute :user_name, Types::String
    attribute :complete, Types::Bool
    attribute :edi_out_filename, Types::String
    attribute :record_id, Types::Integer
    attribute :edi_out_rule_id, Types::Integer
    attribute :party_role_id, Types::Integer
    attribute :error_message, Types::String
    attribute :backtrace, Types::String
  end
end
