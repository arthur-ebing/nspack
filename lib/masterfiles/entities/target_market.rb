# frozen_string_literal: true

module MasterfilesApp
  class TargetMarket < Dry::Struct
    attribute :id, Types::Integer
    attribute :target_market_name, Types::String
    attribute :country_ids, Types::Array
    attribute :tm_group_ids, Types::Array
    attribute :description, Types::String
    attribute :inspection_tm, Types::Bool
    attribute :target_customer_ids, Types::Array
  end
end
