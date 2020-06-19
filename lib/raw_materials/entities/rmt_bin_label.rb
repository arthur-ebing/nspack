# frozen_string_literal: true

module RawMaterialsApp
  class RmtBinLabel < Dry::Struct
    attribute :id, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :puc_id, Types::Integer
    attribute :orchard_id, Types::Integer
    attribute :bin_received_at, Types::DateTime
    attribute :bin_asset_number, Types::String
  end
end
