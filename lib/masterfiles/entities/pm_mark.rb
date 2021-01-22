# frozen_string_literal: true

module MasterfilesApp
  class PmMark < Dry::Struct
    attribute :id, Types::Integer
    attribute :mark_id, Types::Integer
    attribute :mark_code, Types::String
    attribute :packaging_marks, Types::Array
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end
end
