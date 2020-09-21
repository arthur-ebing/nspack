# frozen_string_literal: true

module RawMaterialsApp
  class RmtDelivery < Dry::Struct
    attribute :id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :puc_id, Types::Integer
    attribute :orchard_id, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :rmt_delivery_destination_id, Types::Integer
    attribute :season_id, Types::Integer
    attribute :truck_registration_number, Types::String
    attribute :qty_damaged_bins, Types::Integer
    attribute :qty_empty_bins, Types::Integer
    attribute :delivery_tipped, Types::Bool
    attribute :date_picked, Types::Date
    attribute :received, Types::Bool
    attribute :date_delivered, Types::DateTime
    attribute :tipping_complete_date_time, Types::DateTime
    attribute? :keep_open, Types::Bool
    attribute? :auto_allocate_asset_number, Types::Bool
    attribute? :current, Types::Bool
    attribute? :active, Types::Bool
    attribute? :quantity_bins_with_fruit, Types::Integer
    attribute :reference_number, Types::String
    attribute :batch_number, Types::String
    attribute :batch_number_updated_at, Types::String
  end
end
