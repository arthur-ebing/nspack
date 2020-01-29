# frozen_string_literal: true

module EdiApp
  class EdiInTransaction < Dry::Struct
    attribute :id, Types::Integer
    attribute :file_name, Types::String
    attribute :flow_type, Types::String
    attribute :complete, Types::Bool
    attribute :error_message, Types::String
    attribute :backtrace, Types::String
  end
end
