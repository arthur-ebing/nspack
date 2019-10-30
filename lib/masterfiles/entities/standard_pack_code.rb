# frozen_string_literal: true

module MasterfilesApp
  class StandardPackCode < Dry::Struct
    attribute :id, Types::Integer
    attribute :standard_pack_code, Types::String
    attribute :material_mass, Types::Decimal
    attribute :plant_resource_button_indicator, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end
end
