# frozen_string_literal: true

module MasterfilesApp
  class Supplier < Dry::Struct
    attribute :id, Types::Integer
    attribute? :party_role_id, Types::String
    attribute :supplier_party_role_id, Types::Integer
    attribute :supplier, Types::String
    attribute :supplier_group_ids, Types::Array
    attribute :supplier_group_codes, Types::String
    attribute :farm_ids, Types::Array
    attribute :farm_codes, Types::String
    attribute? :active, Types::Bool
  end
end
