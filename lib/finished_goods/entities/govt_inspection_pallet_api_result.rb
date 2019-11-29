# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionPalletApiResult < Dry::Struct
    attribute :id, Types::Integer
    attribute :passed, Types::Bool
    attribute :failure_reasons, Types::Hash
    attribute :govt_inspection_pallet_id, Types::Integer
    attribute :govt_inspection_api_result_id, Types::Integer
    attribute? :active, Types::Bool
  end
end
