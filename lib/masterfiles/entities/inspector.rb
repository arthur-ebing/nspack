# frozen_string_literal: true

module MasterfilesApp
  class Inspector < Dry::Struct
    attribute :id, Types::Integer
    attribute? :party_role_id, Types::String
    attribute :inspector_party_role_id, Types::Integer
    attribute :inspector, Types::String
    attribute :tablet_ip_address, Types::String
    attribute :tablet_port_number, Types::Integer
    attribute :inspector_code, Types::String
    attribute? :active, Types::Bool
  end
end
