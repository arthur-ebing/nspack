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
    attribute :inspection_type_ids, Types::Array
    attribute :passed_default, Types::Array
    attribute :tm_group_ids, Types::Array
    attribute :grade_ids, Types::Array
  end

  class PalletForTitan < Dry::Struct
    attribute :pallet_id, Types::Integer
    attribute :pallet_number, Types::String
    attribute :govt_inspection_pallet_id, Types::Integer
    attribute :govt_inspection_sheet_id, Types::Integer
    attribute :oldest_pallet_sequence_id, Types::Integer
    attribute :nett_weight, Types::String
    attribute :gross_weight, Types::String
  end

  class PalletSequenceForTitan < Dry::Struct
    attribute :pallet_id, Types::Integer
    attribute :pallet_number, Types::String
    attribute :pallet_sequence_number, Types::String
    attribute :phyto_data, Types::String
    attribute :commodity_code, Types::String
    attribute :commodity_description, Types::String
    attribute :marketing_variety_code, Types::String
    attribute :grade_code, Types::String
    attribute :puc_code, Types::String
    attribute :orchard_code, Types::String
    attribute :production_region_code, Types::String
    attribute :fruit_size_reference, Types::String
    attribute :standard_pack_code, Types::String
    attribute :pallet_percentage, Types::String
    attribute :nett_weight, Types::String
  end
end
