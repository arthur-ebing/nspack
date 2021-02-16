# frozen_string_literal: true

module MasterfilesApp
  class Registration < Dry::Struct
    attribute :id, Types::Integer
    attribute :party_role_id, Types::Integer
    attribute :party_id, Types::Integer
    attribute :role_name, Types::String
    attribute :party_name, Types::String
    attribute :registration_type, Types::String
    attribute :registration_code, Types::String
  end
end
