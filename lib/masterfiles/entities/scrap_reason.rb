# frozen_string_literal: true

module MasterfilesApp
  class ScrapReason < Dry::Struct
    attribute :id, Types::Integer
    attribute :scrap_reason, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
    attribute :applies_to_pallets, Types::Bool
    attribute :applies_to_bins, Types::Bool
  end
end
