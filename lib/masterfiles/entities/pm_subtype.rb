# frozen_string_literal: true

module MasterfilesApp
  class PmSubtype < Dry::Struct
    attribute :id, Types::Integer
    attribute :pm_type_id, Types::Integer
    attribute :subtype_code, Types::String
    attribute :description, Types::String
    attribute :pm_type_code, Types::String
    attribute :short_code, Types::String
    attribute :composition_level, Types::Integer
    attribute :composition_level_description, Types::String
    attribute :minimum_composition_level, Types::Bool
    attribute :fruit_composition_level, Types::Bool
    attribute? :active, Types::Bool
  end
end
