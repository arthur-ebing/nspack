# frozen_string_literal: true

module EdiApp
  class EdiInTransaction < Dry::Struct
    attribute :id, Types::Integer
    attribute :file_name, Types::String
    attribute :flow_type, Types::String
    attribute :complete, Types::Bool
    attribute :error_message, Types::String
    attribute :backtrace, Types::String
    attribute :schema_valid, Types::Bool
    attribute :newer_edi_received, Types::Bool
    attribute :has_missing_master_files, Types::Bool
    attribute :valid, Types::Bool
    attribute :has_discrepancies, Types::Bool
    attribute :reprocessed, Types::Bool
    attribute :notes, Types::String
    attribute :match_data, Types::String
  end
end
