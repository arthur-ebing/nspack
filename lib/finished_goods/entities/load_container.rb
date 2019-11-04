# frozen_string_literal: true

module FinishedGoodsApp
  class LoadContainer < Dry::Struct
    attribute :id, Types::Integer
    attribute :load_id, Types::Integer
    attribute :container_code, Types::String
    attribute :container_vents, Types::String
    attribute :container_seal_code, Types::String
    attribute :internal_container_code, Types::String
    attribute :container_temperature_rhine, Types::Decimal
    attribute :container_temperature_rhine2, Types::Decimal
    attribute :max_gross_weight, Types::Decimal
    attribute :tare_weight, Types::Decimal
    attribute :max_payload, Types::Decimal
    attribute :actual_payload, Types::Decimal
    attribute :cargo_temperature_id, Types::Integer
    attribute :stack_type_id, Types::Integer
    attribute :verified_gross_weight, Types::Decimal
    attribute :verified_gross_weight_date, Types::DateTime
    attribute? :active, Types::Bool
  end
end
