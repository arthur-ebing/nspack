# frozen_string_literal: true

module MasterfilesApp
  class MarketingVariety < Dry::Struct
    attribute :id, Types::Integer
    attribute :marketing_variety_code, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
    attribute :inspection_variety, Types::String
  end
end
