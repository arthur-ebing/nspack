# frozen_string_literal: true

module ProductionApp
  class MarketingOrder < Dry::Struct
    attribute :id, Types::Integer
    attribute :customer_party_role_id, Types::Integer
    attribute :season_id, Types::Integer
    attribute :order_number, Types::String
    attribute :order_reference, Types::String
    attribute :completed, Types::Bool
    attribute :completed_at, Types::DateTime
  end
end
