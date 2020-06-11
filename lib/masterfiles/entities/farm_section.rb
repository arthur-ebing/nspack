# frozen_string_literal: true

module MasterfilesApp
  class FarmSection < Dry::Struct
    attribute :id, Types::Integer
    attribute :farm_manager_party_role_id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :farm_section_name, Types::String
    attribute :description, Types::String
    attribute :orchard_ids, Types::Array
  end

  class FarmSectionFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :farm_manager_party_role_id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :farm_section_name, Types::String
    attribute :farm_manager_party_role, Types::String
    attribute :description, Types::String
    attribute :orchard_ids, Types::Array
    attribute :orchards, Types::String
    attribute :status, Types::String
  end
end
