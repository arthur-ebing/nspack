# frozen_string_literal: true

module MesscadaApp
  class Pallet < Dry::Struct
    attribute :id, Types::Integer
    attribute :pallet_number, Types::String
    attribute :exit_ref, Types::String
    attribute :scrapped_at, Types::DateTime
    attribute :location_id, Types::Integer
    attribute? :shipped, Types::Bool
    attribute? :in_stock, Types::Bool
    attribute? :inspected, Types::Bool
    attribute :shipped_at, Types::DateTime
    attribute :govt_first_inspection_at, Types::DateTime
    attribute :govt_reinspection_at, Types::DateTime
    attribute :internal_inspection_at, Types::DateTime
    attribute :internal_reinspection_at, Types::DateTime
    attribute :stock_created_at, Types::DateTime
    attribute :phc, Types::String
    attribute :intake_created_at, Types::DateTime
    attribute :first_cold_storage_at, Types::DateTime
    attribute :build_status, Types::String
    attribute :gross_weight, Types::Decimal
    attribute :gross_weight_measured_at, Types::DateTime
    attribute? :palletized, Types::Bool
    attribute? :partially_palletized, Types::Bool
    attribute :palletized_at, Types::DateTime
    attribute :partially_palletized_at, Types::DateTime
    attribute :fruit_sticker_pm_product_id, Types::Integer
    attribute? :allocated, Types::Bool
    attribute :allocated_at, Types::DateTime
    attribute? :reinspected, Types::Bool
    attribute? :scrapped, Types::Bool
    attribute :pallet_format_id, Types::Integer
    attribute :carton_quantity, Types::Integer
    attribute? :govt_inspection_passed, Types::Bool
    attribute? :internal_inspection_passed, Types::Bool
    attribute :plt_packhouse_resource_id, Types::Integer
    attribute :plt_line_resource_id, Types::Integer
    attribute :nett_weight, Types::Decimal
    attribute? :active, Types::Bool
  end
end
