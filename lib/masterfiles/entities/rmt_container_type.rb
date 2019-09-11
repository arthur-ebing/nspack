# frozen_string_literal: true

module MasterfilesApp
  class RmtContainerType < Dry::Struct
    attribute :id, Types::Integer
    attribute :container_type_code, Types::String
    attribute :description, Types::String
    attribute :tare_weight, Types::Decimal
    attribute :rmt_inner_container_type_id, Types::Integer
    attribute? :active, Types::Bool
  end
end
