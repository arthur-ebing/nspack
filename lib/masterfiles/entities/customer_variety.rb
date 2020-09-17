# frozen_string_literal: true

module MasterfilesApp
  class CustomerVariety < Dry::Struct
    attribute :id, Types::Integer
    attribute :variety_as_customer_variety_id, Types::Integer
    attribute :packed_tm_group_id, Types::Integer
    attribute? :active, Types::Bool
    attribute :variety_as_customer_variety, Types::String
    attribute :packed_tm_group, Types::String
    attribute :customer_variety_varieties, Types::Array.default([].freeze) do
      attribute :marketing_variety_id, Types::Integer
    end
  end
end
