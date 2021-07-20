# frozen_string_literal: true

module FinishedGoodsApp
  class Inspection < Dry::Struct
    attribute :id, Types::Integer
    attribute :inspection_type_id, Types::Integer
    attribute :inspection_type_code, Types::String
    attribute :pallet_id, Types::Integer
    attribute :pallet_number, Types::String
    attribute :carton_id, Types::Integer
    attribute :inspector_id, Types::Integer
    attribute :inspector, Types::String
    attribute :inspected, Types::Bool
    attribute :inspection_failure_reason_ids, Types::Array
    attribute :failure_reasons, Types::Array
    attribute :passed, Types::Bool
    attribute :remarks, Types::String
    attribute? :active, Types::Bool
  end

  class PalletForInspection < Dry::Struct
    attribute :pallet_id, Types::Integer
    attribute :pallet_number, Types::String
    attribute :palletized, Types::Bool
    attribute :inspection_type_ids, Types::Array
    attribute :passed_default, Types::Array
    attribute :tm_ids, Types::Array
    attribute :tm_customer_ids, Types::Array
    attribute :grade_ids, Types::Array
  end

  class PalletForTitan < Dry::Struct
    attribute :commodity, Types::String
    attribute :commodity_description, Types::String
    attribute :consignment_note_number, Types::String
    attribute :container, Types::String
    attribute :govt_inspection_pallet_id, Types::Integer
    attribute :govt_inspection_sheet_id, Types::Integer
    attribute :grade, Types::String
    attribute :marketing_variety, Types::String
    attribute :gross_weight_per_carton, Types::Decimal
    attribute :nett_weight_per_carton, Types::Decimal
    attribute :pallet_carton_quantity, Types::Decimal
    attribute :pallet_id, Types::Integer
    attribute :pallet_number, Types::String
    attribute :phc, Types::String
    attribute :shipped_at, Types::DateTime
    attribute :bin, Types::Bool
  end

  class PalletSequenceForTitan < Dry::Struct
    attribute :actual_count, Types::String
    attribute :carton_quantity, Types::Decimal
    attribute :commodity, Types::String
    attribute :commodity_description, Types::String
    attribute :grade, Types::String
    attribute :marketing_variety, Types::String
    attribute :nett_weight, Types::Decimal
    attribute :orchard, Types::String
    attribute :pallet_carton_quantity, Types::Decimal
    attribute :pallet_id, Types::Integer
    attribute :pallet_number, Types::String
    attribute :pallet_percentage, Types::Decimal
    attribute :pallet_sequence_number, Types::String
    attribute :palletized_at, Types::DateTime
    attribute :partially_palletized_at, Types::DateTime
    attribute :phyto_data, Types::String
    attribute :production_region, Types::String
    attribute :puc, Types::String
    attribute :size_ref, Types::String
    attribute :std_pack, Types::String
    attribute :inventory_code, Types::String
  end
end
