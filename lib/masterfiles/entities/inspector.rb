# frozen_string_literal: true

module MasterfilesApp
  class Inspector < Dry::Struct
    attribute :id, Types::Integer
    attribute :inspector_party_role_id, Types::Integer
    attribute :tablet_ip_address, Types::String
    attribute :tablet_port_number, Types::Integer
    attribute? :active, Types::Bool
  end

  class InspectorFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :inspector_party_role_id, Types::Integer
    attribute :inspector, Types::String
    attribute :tablet_ip_address, Types::String
    attribute :tablet_port_number, Types::Integer
    attribute? :active, Types::Bool
  end
end
