# frozen_string_literal: true

module ProductionApp
  class ProductionRunStat < Dry::Struct
    attribute :id, Types::Integer
    attribute :production_run_id, Types::Integer
    attribute :bins_tipped, Types::Integer
    attribute :bins_tipped_weight, Types::Decimal
    attribute :carton_labels_printed, Types::Integer
    attribute :cartons_verified, Types::Integer
    attribute :cartons_verified_weight, Types::Decimal
    attribute :pallets_palletized_full, Types::Integer
    attribute :inspected_pallets, Types::Integer
    attribute :rebins_created, Types::Integer
    attribute :rebins_weight, Types::Decimal
    attribute :pallets_palletized_partial, Types::Integer
  end
end
