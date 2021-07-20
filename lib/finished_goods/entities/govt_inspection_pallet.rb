# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionPallet < Dry::Struct
    attribute :id, Types::Integer
    attribute :pallet_id, Types::Integer
    attribute :pallet_number, Types::String
    attribute :govt_inspection_sheet_id, Types::Integer
    attribute :completed, Types::Bool
    attribute :passed, Types::Bool
    attribute :inspected, Types::Bool
    attribute :inspected_at, Types::DateTime
    attribute :failure_reason_id, Types::Integer
    attribute :failure_reason, Types::String
    attribute :description, Types::String
    attribute :main_factor, Types::Bool
    attribute :secondary_factor, Types::Bool
    attribute :failure_remarks, Types::String
    attribute :sheet_inspected, Types::Bool
    attribute :nett_weight, Types::Decimal
    attribute :gross_weight, Types::Decimal
    attribute :carton_quantity, Types::Integer
    attribute :marketing_varieties, Types::Array
    attribute :packed_tm_groups, Types::Array
    attribute :pallet_base, Types::String
    attribute? :status, Types::String
    attribute? :colour_rule, Types::String
    attribute? :active, Types::Bool
  end

  class PalletFlat < Dry::Struct
    attribute :pallet_number, Types::String
    attribute :gross_weight, Types::Float
    attribute :carton_quantity, Types::Integer
    attribute :marketing_varieties, Types::Array
    attribute :packed_tm_groups, Types::Array
    attribute :pallet_base, Types::String
  end
end
