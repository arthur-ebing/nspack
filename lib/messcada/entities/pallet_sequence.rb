# frozen_string_literal: true

module MesscadaApp
  class PalletSequence < Dry::Struct
    attribute :id, Types::Integer
    attribute :pallet_id, Types::Integer
    attribute :pallet_number, Types::String
    attribute :pallet_sequence_number, Types::Integer
    attribute :production_run_id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :puc_id, Types::Integer
    attribute :orchard_id, Types::Integer
    attribute :cultivar_group_id, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :product_resource_allocation_id, Types::Integer
    attribute :packhouse_resource_id, Types::Integer
    attribute :production_line_id, Types::Integer
    attribute :season_id, Types::Integer
    attribute :marketing_variety_id, Types::Integer
    attribute :customer_variety_variety_id, Types::Integer
    attribute :std_fruit_size_count_id, Types::Integer
    attribute :basic_pack_code_id, Types::Integer
    attribute :standard_pack_code_id, Types::Integer
    attribute :fruit_actual_counts_for_pack_id, Types::Integer
    attribute :fruit_size_reference_id, Types::Integer
    attribute :marketing_org_party_role_id, Types::Integer
    attribute :packed_tm_group_id, Types::Integer
    attribute :mark_id, Types::Integer
    attribute :inventory_code_id, Types::Integer
    attribute :pallet_format_id, Types::Integer
    attribute :cartons_per_pallet_id, Types::Integer
    attribute :pm_bom_id, Types::Integer
    attribute :extended_columns, Types::Hash
    attribute :client_size_reference, Types::String
    attribute :client_product_code, Types::String
    attribute :treatment_ids, Types::Array
    attribute :marketing_order_number, Types::String
    attribute :pm_type_id, Types::Integer
    attribute :pm_subtype_id, Types::Integer
    attribute :carton_quantity, Types::Integer
    attribute :scanned_from_carton_id, Types::Integer
    attribute :exit_ref, Types::String
    attribute :scrapped_at, Types::DateTime
    attribute :verification_result, Types::String
    attribute :pallet_verification_failure_reason_id, Types::Integer
    attribute :verified_at, Types::DateTime
    attribute :nett_weight, Types::Decimal
    attribute? :verified, Types::Bool
    attribute? :verification_passed, Types::Bool
    attribute :pick_ref, Types::String
    attribute? :active, Types::Bool
    attribute :grade_id, Types::Integer
    attribute :verified_by, Types::String
    attribute :created_by, Types::String
  end
end
