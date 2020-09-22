# frozen_string_literal: true

module MesscadaApp
  class PalletSequenceContract < Dry::Validation::Contract
    params do # rubocop:disable Metrics/BlockLength
      optional(:id).filled(:integer)
      optional(:pallet_id).filled(:integer)
      optional(:pallet_number).filled(Types::StrippedString)
      optional(:pallet_sequence_number).filled(:integer)
      required(:production_run_id).filled(:integer)
      optional(:farm_id).filled(:integer)
      required(:puc_id).filled(:integer)
      required(:orchard_id).filled(:integer)
      required(:cultivar_group_id).filled(:integer)
      optional(:cultivar_id).maybe(:integer)
      required(:product_resource_allocation_id).maybe(:integer)
      required(:packhouse_resource_id).filled(:integer)
      optional(:production_line_id).filled(:integer)
      required(:season_id).filled(:integer)
      required(:marketing_variety_id).filled(:integer)
      optional(:customer_variety_id).maybe(:integer)
      optional(:std_fruit_size_count_id).maybe(:integer)
      required(:basic_pack_code_id).filled(:integer)
      required(:standard_pack_code_id).filled(:integer)
      required(:fruit_actual_counts_for_pack_id).maybe(:integer)
      required(:fruit_size_reference_id).maybe(:integer)
      required(:marketing_org_party_role_id).filled(:integer)
      required(:packed_tm_group_id).filled(:integer)
      required(:mark_id).filled(:integer)
      required(:inventory_code_id).filled(:integer)
      required(:pallet_format_id).filled(:integer)
      required(:cartons_per_pallet_id).filled(:integer)
      required(:pm_bom_id).maybe(:integer)
      optional(:extended_columns).maybe(:hash)
      optional(:client_size_reference).maybe(Types::StrippedString)
      optional(:client_product_code).maybe(Types::StrippedString)
      optional(:treatment_ids).filled(:array).maybe { each(:integer) }
      optional(:marketing_order_number).maybe(Types::StrippedString)
      optional(:pm_type_id).maybe(:integer)
      optional(:pm_subtype_id).maybe(:integer)
      required(:carton_quantity).filled(:integer)
      required(:scanned_from_carton_id).maybe(:integer)
      optional(:exit_ref).maybe(Types::StrippedString)
      optional(:scrapped_at).maybe(:time)
      optional(:verification_result).maybe(Types::StrippedString)
      optional(:pallet_verification_failure_reason_id).maybe(:integer)
      optional(:verified_at).maybe(:time)
      optional(:nett_weight).maybe(:decimal)
      optional(:verified).maybe(:bool)
      optional(:verification_passed).maybe(:bool)
      required(:pick_ref).maybe(Types::StrippedString)
      required(:grade_id).filled(:integer)
      optional(:scrapped_from_pallet_id).maybe(:integer)
      optional(:removed_from_pallet).maybe(:bool)
      optional(:removed_from_pallet_at).maybe(:time)
      optional(:removed_from_pallet_id).maybe(:integer)
      optional(:verified_by).maybe(Types::StrippedString)
      optional(:created_by).maybe(Types::StrippedString)
    end

    rule(:fruit_size_reference_id, :fruit_actual_counts_for_pack_id) do
      base.failure 'must provide either fruit_size_reference or fruit_actual_count' unless values[:fruit_size_reference_id] || values[:fruit_actual_counts_for_pack_id]
    end
  end
end
