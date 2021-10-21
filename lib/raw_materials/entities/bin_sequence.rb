# frozen_string_literal: true

module RawMaterialsApp
  class BinSequence < Dry::Struct
    attribute :id, Types::Integer
    attribute :rmt_bin_id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :orchard_id, Types::Integer
    attribute :nett_weight, Types::Decimal
    attribute :presort_run_lot_number, Types::String
  end
end
