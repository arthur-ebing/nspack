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
end
