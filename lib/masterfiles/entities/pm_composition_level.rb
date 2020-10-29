# frozen_string_literal: true

module MasterfilesApp
  class PmCompositionLevel < Dry::Struct
    attribute :id, Types::Integer
    attribute :composition_level, Types::Integer
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end
end
