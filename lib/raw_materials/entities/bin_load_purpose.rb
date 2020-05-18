# frozen_string_literal: true

module RawMaterialsApp
  class BinLoadPurpose < Dry::Struct
    attribute :id, Types::Integer
    attribute :purpose_code, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end
end
