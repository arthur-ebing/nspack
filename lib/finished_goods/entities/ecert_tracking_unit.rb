# frozen_string_literal: true

module FinishedGoodsApp
  class EcertTrackingUnit < Dry::Struct
    attribute :id, Types::Integer
    attribute :pallet_id, Types::Integer
    attribute :ecert_agreement_id, Types::Integer
    attribute :ecert_agreement_code, Types::String
    attribute :ecert_agreement_name, Types::String
    attribute :pallet_number, Types::String
    attribute :business_id, Types::Integer
    attribute :industry, Types::String
    attribute :elot_key, Types::String
    attribute :verification_key, Types::String
    attribute :passed, Types::Bool
    attribute :process_result, Types::Array
    attribute :rejection_reasons, Types::Array
    attribute? :active, Types::Bool
  end
end
