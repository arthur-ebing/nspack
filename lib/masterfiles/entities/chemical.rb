# frozen_string_literal: true

module MasterfilesApp
  class Chemical < Dry::Struct
    attribute :id, Types::Integer
    attribute :chemical_name, Types::String
    attribute :description, Types::String
    attribute :eu_max_level, Types::Decimal
    attribute :arfd_max_level, Types::Decimal
    attribute :orchard_chemical, Types::Bool
    attribute :drench_chemical, Types::Bool
    attribute :packline_chemical, Types::Bool
    attribute? :active, Types::Bool
  end
end
