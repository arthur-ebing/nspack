# frozen_string_literal: true

module MasterfilesApp
  class PmSubtype < Dry::Struct
    attribute :id, Types::Integer
    attribute :pm_type_id, Types::Integer
    attribute :subtype_code, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
    attribute :pm_type_code, Types::String
    attribute :short_code, Types::String
  end
end
