# frozen_string_literal: true

module MasterfilesApp
  class MrlSampleType < Dry::Struct
    attribute :id, Types::Integer
    attribute :sample_type_code, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end
end
