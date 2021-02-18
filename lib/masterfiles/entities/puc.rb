# frozen_string_literal: true

module MasterfilesApp
  class Puc < Dry::Struct
    attribute :id, Types::Integer
    attribute :puc_code, Types::String
    attribute :gap_code, Types::String
    attribute? :active, Types::Bool
    attribute :gap_code_valid_from, Types::DateTime
    attribute :gap_code_valid_until, Types::DateTime
  end
end
