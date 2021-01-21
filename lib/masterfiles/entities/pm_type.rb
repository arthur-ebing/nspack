# frozen_string_literal: true

module MasterfilesApp
  class PmType < Dry::Struct
    attribute :id, Types::Integer
    attribute :pm_type_code, Types::String
    attribute :description, Types::String
    attribute :pm_composition_level_id, Types::Integer
    attribute :composition_level, Types::String
    attribute :composition_level_description, Types::String
    attribute :short_code, Types::String
    attribute? :active, Types::Bool
  end
end
