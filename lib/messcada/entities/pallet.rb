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
    attribute :fruit_sticker_pm_product_2_id, Types::Integer
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
    attribute :load_id, Types::Integer
    attribute? :cooled, Types::Bool
    attribute :palletizing_bay_resource_id, Types::Integer
    attribute? :has_individual_cartons, Types::Bool
  end

  class PalletFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :pallet_number, Types::String
    attribute :exit_ref, Types::String
    attribute :scrapped_at, Types::DateTime
    attribute :location_id, Types::Integer

    attribute :shipped, Types::Bool
    attribute :shipped_at, Types::DateTime
    attribute :in_stock, Types::Bool

    attribute :inspected, Types::Bool
    attribute :govt_first_inspection_at, Types::DateTime
    attribute :govt_reinspection_at, Types::DateTime
    attribute :govt_inspection_passed, Types::Bool
    attribute :last_govt_inspection_pallet_id, Types::Integer
    attribute :last_govt_inspection_sheet_id, Types::Integer

    attribute :internal_inspection_at, Types::DateTime
    attribute :internal_reinspection_at, Types::DateTime
    attribute :stock_created_at, Types::DateTime
    attribute :phc, Types::String
    attribute :intake_created_at, Types::DateTime
    attribute :first_cold_storage_at, Types::DateTime
    attribute :build_status, Types::String
    attribute :gross_weight, Types::Decimal
    attribute :gross_weight_measured_at, Types::DateTime
    attribute :palletized, Types::Bool
    attribute :partially_palletized, Types::Bool
    attribute :palletized_at, Types::DateTime
    attribute :partially_palletized_at, Types::DateTime
    attribute :fruit_sticker_pm_product_id, Types::Integer
    attribute :allocated, Types::Bool
    attribute :allocated_at, Types::DateTime
    attribute :reinspected, Types::Bool
    attribute :scrapped, Types::Bool
    attribute :pallet_format_id, Types::Integer
    attribute :carton_quantity, Types::Integer
    attribute :internal_inspection_passed, Types::Bool
    attribute :plt_packhouse_resource_id, Types::Integer
    attribute :plt_line_resource_id, Types::Integer
    attribute :nett_weight, Types::Decimal
    attribute :load_id, Types::Integer
    attribute :cooled, Types::Bool
    attribute :fruit_sticker_pm_product_2_id, Types::Integer
    attribute :temp_tail, Types::String
    attribute :depot_pallet, Types::Bool
    attribute :edi_in_transaction_id, Types::Integer
    attribute :edi_in_consignment_note_number, Types::String
    attribute :edi_in_inspection_point, Types::String
    attribute :repacked, Types::Bool
    attribute :repacked_at, Types::DateTime
    attribute :target_customer_party_role_id, Types::Integer
    attribute :target_customer, Types::String
    attribute :palletizing_bay_resource_id, Types::Integer
    attribute :has_individual_cartons, Types::Bool
    attribute :oldest_pallets_sequence_id, Types::Integer
    attribute :pallet_sequence_ids, Types::IntArray
    attribute? :status, Types::String
    attribute? :active, Types::Bool
  end

  class ScannedPalletNumber < Dry::Struct
    attribute :scanned_pallet_number, Types::String

    # Munge the scanned pallet number to get a valid number
    # by discarding extra characters from known deviations.
    def pallet_number # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      return nil if scanned_pallet_number.nil_or_empty?

      case scanned_pallet_number.length
      when 9, 18
        scanned_pallet_number
      when 11
        raise Crossbeams::InfoError, "Pallet #{scanned_pallet_number} is not a recognised format for 11 digits." unless %w[46 47 48 49].include?(scanned_pallet_number[0, 2])

        scanned_pallet_number[-9, 9]
      when 15
        raise Crossbeams::InfoError, "Pallet #{scanned_pallet_number} is not a recognised format for 15 digits." unless scanned_pallet_number.start_with?(']C')

        scanned_pallet_number[-9, 9]
      when 19
        raise Crossbeams::InfoError, "Pallet #{scanned_pallet_number} is not a recognised format for 19 digits." unless scanned_pallet_number.start_with?('0')

        scanned_pallet_number.delete_prefix('0')
      when 20, 21, 23
        scanned_pallet_number[-18, 18]
      else
        raise Crossbeams::InfoError, "Scan #{scanned_pallet_number} is not a recognised pallet number length."
      end
    end
  end
end
