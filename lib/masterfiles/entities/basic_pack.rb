# frozen_string_literal: true

module MasterfilesApp
  class BasicPack < Dry::Struct
    attribute :id, Types::Integer
    attribute :basic_pack_code, Types::String
    attribute :description, Types::String
    attribute :length_mm, Types::Integer
    attribute :width_mm, Types::Integer
    attribute :height_mm, Types::Integer
    attribute :footprint_code, Types::String
    attribute :standard_pack_ids, Types::Array
    attribute :standard_pack_codes, Types::Array
    attribute? :active, Types::Bool
  end
end
