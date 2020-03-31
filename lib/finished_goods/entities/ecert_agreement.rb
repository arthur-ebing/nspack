# frozen_string_literal: true

module FinishedGoodsApp
  class EcertAgreement < Dry::Struct
    attribute :id, Types::Integer
    attribute :code, Types::String
    attribute :name, Types::String
    attribute :description, Types::String
    attribute :start_date, Types::Date
    attribute :end_date, Types::Date
    attribute? :active, Types::Bool
  end
end
