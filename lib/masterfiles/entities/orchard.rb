# frozen_string_literal: true

module MasterfilesApp
  class Orchard < Dry::Struct
    attribute :id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :puc_id, Types::Integer
    attribute :farm_manager_party_role_id, Types::Integer
    attribute :orchard_code, Types::String
    attribute :description, Types::String
    attribute :cultivar_ids, Types::Array
    attribute :puc_code, Types::String
    attribute :cultivar_names, Types::String
    attribute :farm_section_name, Types::String
    attribute? :active, Types::Bool
    attribute :cultivars, Types::Array.default([].freeze) do
      attribute :id, Types::Integer
      attribute :cultivar_name, Types::String
    end
  end
end
