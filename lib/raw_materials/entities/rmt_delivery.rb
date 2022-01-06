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
    attribute :tripsheet_created_at, Types::DateTime
    attribute :tripsheet_offloaded_at, Types::DateTime
    attribute :tripsheet_loaded_at, Types::DateTime
    attribute? :keep_open, Types::Bool
    attribute? :bin_scan_mode, Types::Integer
    attribute? :current, Types::Bool
    attribute? :active, Types::Bool
    attribute? :shipped, Types::Bool
    attribute? :tripsheet_created, Types::Bool
    attribute? :tripsheet_loaded, Types::Bool
    attribute? :tripsheet_offloaded, Types::Bool
    attribute? :quantity_bins_with_fruit, Types::Integer
    attribute :reference_number, Types::String
    attribute :batch_number, Types::String
    attribute :sample_bins, Types::Array
    attribute :batch_number_updated_at, Types::DateTime
    attribute :rmt_container_type_id, Types::Integer
    attribute :rmt_material_owner_party_role_id, Types::Integer
    attribute :rmt_code_id, Types::Integer
    attribute :rmt_classifications, Types::Array
    attribute :rmt_container_material_type_id, Types::Integer
    attribute :qty_partial_bins, Types::Integer
    attribute :sample_bins_weighed, Types::Bool
    attribute :sample_weights_extrapolated_at, Types::DateTime
  end
end
