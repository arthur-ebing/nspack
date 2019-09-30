# frozen_string_literal: true

module MasterfilesApp
  class PortType < Dry::Struct
    attribute :id, Types::Integer
    attribute :port_type_code, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end
end
