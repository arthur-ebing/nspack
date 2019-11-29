# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionPallet < Dry::Struct
    attribute :id, Types::Integer
    attribute :pallet_id, Types::Integer
    attribute :govt_inspection_sheet_id, Types::Integer
    attribute :passed, Types::Bool
    attribute :inspected, Types::Bool
    attribute :inspected_at, Types::DateTime
    attribute :failure_reason_id, Types::Integer
    attribute :failure_remarks, Types::String
    attribute? :active, Types::Bool
  end

  class GovtInspectionPalletFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :pallet_id, Types::Integer
    attribute :govt_inspection_sheet_id, Types::Integer
    attribute :passed, Types::Bool
    attribute :inspected, Types::Bool
    attribute :inspected_at, Types::DateTime
    attribute :failure_reason_id, Types::Integer
    attribute :failure_reason, Types::String
    attribute :description, Types::String
    attribute :main_factor, Types::Bool
    attribute :secondary_factor, Types::Bool
    attribute :failure_remarks, Types::String
    attribute? :status, Types::String
    attribute? :active, Types::Bool
  end
end
