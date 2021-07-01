# frozen_string_literal: true

module ProductionApp  # rubocop:disable Metrics/ModuleLength
  ReworksRunSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:user).filled(Types::StrippedString)
    required(:reworks_run_type_id).filled(:integer)
    optional(:remarks).maybe(Types::StrippedString)
    optional(:scrap_reason_id).maybe(:integer)
    optional(:pallets_selected).maybe(:array).maybe { each(:string) }
    optional(:pallets_affected).maybe(:array).maybe { each(:string) }
    optional(:changes_made).maybe(:hash)
    optional(:pallets_scrapped).maybe(:array).maybe { each(:string) }
    optional(:pallets_unscrapped).maybe(:array).maybe { each(:string) }
  end

  ReworksRunNewSchema = Dry::Schema.Params do
    required(:reworks_run_type_id).filled(:integer)
    required(:pallets_selected).filled(:array).each(:string)
    optional(:make_changes).maybe(:bool)
  end

  ReworksRunScrapPalletsSchema = Dry::Schema.Params do
    required(:reworks_run_type_id).filled(:integer)
    required(:scrap_reason_id).filled(:integer)
    required(:remarks).filled(Types::StrippedString)
    required(:pallets_selected).filled(:array).each(:string)
    optional(:make_changes).maybe(:bool)
  end

  ReworksRunFlatSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:user).filled(Types::StrippedString)
    required(:reworks_run_type_id).filled(:integer)
    optional(:remarks).maybe(Types::StrippedString)
    optional(:scrap_reason_id).maybe(:integer)
    required(:pallets_selected).filled(:array).each(:string)
    optional(:pallets_affected).maybe(:array).maybe { each(:string) }
    optional(:changes_made).maybe(:hash)
    optional(:pallets_scrapped).maybe(:array).maybe { each(:string) }
    optional(:pallets_unscrapped).maybe(:array).maybe { each(:string) }
    optional(:pallet_sequence_id).maybe(:integer)
    optional(:affected_sequences).maybe(:array).maybe { each(:integer) }
    optional(:make_changes).maybe(:bool)
    required(:allow_cultivar_group_mixing).maybe(:bool)
  end

  ReworksRunTipBinsSchema = Dry::Schema.Params do
    required(:reworks_run_type_id).filled(:integer)
    required(:production_run_id).filled(:integer)
    required(:pallets_selected).filled(:array).each(:string)
    optional(:make_changes).maybe(:bool)
    required(:allow_cultivar_mixing).maybe(:bool)
    required(:gross_weight).maybe(:decimal)
    optional(:allow_orchard_mixing).maybe(:bool)
    optional(:tip_orchard_mixing).maybe(:bool)
  end

  ReworksRunPrintBarcodeSchema = Dry::Schema.Params do
    optional(:printer).filled(:integer)
    required(:label_template_id).filled(:integer)
    required(:no_of_prints).filled(:integer, gt?: 0)
    required(:pallet_number).maybe(Types::StrippedString)
    required(:pallet_sequence_id).maybe(:integer)
  end

  ProductionRunUpdateSchema = Dry::Schema.Params do
    required(:pallet_sequence_id).filled(:integer)
    required(:production_run_id).filled(:integer)
    required(:old_production_run_id).filled(:integer)
    required(:reworks_run_type_id).filled(:integer)
    optional(:allow_cultivar_group_mixing).maybe(:bool)
  end

  ProductionRunUpdateFarmDetailsSchema = Dry::Schema.Params do
    required(:pallet_sequence_id).filled(:integer)
    required(:reworks_run_type_id).filled(:integer)
    required(:farm_id).filled(:integer)
    required(:puc_id).filled(:integer)
    required(:orchard_id).maybe(:integer)
    required(:cultivar_group_id).filled(:integer)
    required(:cultivar_id).maybe(:integer)
    required(:season_id).filled(:integer)
  end

  ReworksRunUpdateGrossWeightSchema = Dry::Schema.Params do
    required(:reworks_run_type_id).filled(:integer)
    required(:pallet_number).maybe(Types::StrippedString)
    required(:standard_pack_code_id).filled(:integer)
    required(:gross_weight).filled(:decimal)
  end

  SequenceSetupDataSchema = Dry::Schema.Params do # rubocop:disable Metrics/BlockLength
    optional(:id).filled(:integer)
    required(:marketing_variety_id).filled(:integer)
    required(:customer_variety_id).maybe(:integer)
    required(:std_fruit_size_count_id).maybe(:integer)
    required(:basic_pack_code_id).filled(:integer)
    required(:standard_pack_code_id).filled(:integer)
    required(:fruit_size_reference_id).maybe(:integer)
    required(:marketing_org_party_role_id).filled(:integer)
    required(:packed_tm_group_id).filled(:integer)
    required(:mark_id).filled(:integer)
    required(:inventory_code_id).maybe(:integer)
    required(:pallet_format_id).filled(:integer)
    required(:cartons_per_pallet_id).filled(:integer)
    optional(:pm_bom_id).maybe(:integer)
    # required(:extended_columns).maybe(:hash)
    required(:client_size_reference).maybe(Types::StrippedString)
    required(:client_product_code).maybe(Types::StrippedString)
    optional(:treatment_ids).maybe(:array).maybe { each(:integer) }
    required(:marketing_order_number).maybe(Types::StrippedString)
    required(:sell_by_code).maybe(Types::StrippedString)
    required(:pallet_label_name).maybe(Types::StrippedString)
    required(:grade_id).maybe(:integer)
    required(:product_chars).maybe(Types::StrippedString)
    optional(:pm_type_id).maybe(:integer)
    optional(:pm_subtype_id).maybe(:integer)
    required(:target_market_id).maybe(:integer)
    optional(:pm_mark_id).maybe(:integer)
    optional(:rmt_class_id).maybe(:integer)
    optional(:packing_specification_item_id).maybe(:integer)
    optional(:tu_labour_product_id).maybe(:integer)
    optional(:ru_labour_product_id).maybe(:integer)
    optional(:fruit_sticker_ids).maybe(:array).maybe { each(:integer) }
    optional(:tu_sticker_ids).maybe(:array).maybe { each(:integer) }
    optional(:target_customer_party_role_id).maybe(:integer)
  end

  ReworksRunUpdatePalletSchema = Dry::Schema.Params do
    required(:reworks_run_type_id).filled(:integer)
    required(:pallet_number).maybe(Types::StrippedString)
    required(:fruit_sticker_pm_product_id).filled(:integer)
    required(:fruit_sticker_pm_product_2_id).maybe(:integer)
    optional(:batch_number).maybe(Types::StrippedString)
  end

  EditCartonQuantitySchema = Dry::Schema.Params do
    required(:column_value).filled(:integer, gt?: 0)
  end

  ManuallyWeighRmtBinSchema = Dry::Schema.Params do
    required(:reworks_run_type_id).filled(:integer)
    required(:bin_number).maybe(Types::StrippedString)
    required(:gross_weight).filled(:decimal)
    required(:measurement_unit).maybe(Types::StrippedString)
  end

  ChangeDeliveriesOrchardSchema = Dry::Schema.Params do
    required(:to_orchard).filled(:integer)
    optional(:from_cultivar).maybe(:integer)
    required(:from_orchard).filled(:integer)
    required(:to_cultivar).filled(:integer)
  end

  FromCultivarSchema = Dry::Schema.Params do
    required(:from_cultivar).filled(:integer)
  end

  ChangeCultivarOnlyCultivarSchema = Dry::Schema.Params do
    required(:allow_cultivar_mixing).filled(:bool)
  end

  ReworksRunBulkProductionRunUpdateSchema = Dry::Schema.Params do
    required(:reworks_run_type_id).filled(:integer)
    required(:pallets_selected).maybe(:array).each(:string)
    required(:from_production_run_id).filled(:integer)
    required(:to_production_run_id).filled(:integer)
    optional(:make_changes).maybe(:bool)
    optional(:allow_cultivar_group_mixing).maybe(:bool)
  end

  ReworksBulkWeighBinsSchema = Dry::Schema.Params do
    required(:reworks_run_type_id).filled(:integer)
    required(:pallets_selected).filled(:array).each(:string)
    optional(:make_changes).maybe(:bool)
    required(:gross_weight).filled(:decimal)
    required(:avg_gross_weight).maybe(:bool)
  end

  ReworksOrchardChangeSchema = Dry::Schema.Params do
    required(:delivery_ids).filled(:array).each(:integer)
    required(:from_orchard).filled(:integer)
    required(:from_cultivar).maybe(:integer)
    required(:to_orchard).filled(:integer)
    required(:to_cultivar).filled(:integer)
    required(:allow_cultivar_mixing).maybe(:bool)
    required(:ignore_runs_that_allow_mixing).maybe(:bool)
  end

  ReworksBulkUpdatePalletDatesSchema = Dry::Schema.Params do
    required(:reworks_run_type_id).filled(:integer)
    required(:pallets_selected).filled(:array).each(:string)
    required(:first_cold_storage_at).filled(:date)
    optional(:make_changes).maybe(:bool)
  end

  ReworksRunCloneCartonSchema = Dry::Schema.Params do
    required(:carton_id).filled(:integer)
    required(:pallet_id).filled(:integer)
    required(:pallet_sequence_id).filled(:integer)
    required(:no_of_clones).filled(:integer, gt?: 0)
  end

  ReworksRunCloneSequenceSchema = Dry::Schema.Params do
    required(:reworks_run_type_id).filled(:integer)
    required(:pallet_id).filled(:integer)
    required(:pallet_sequence_id).filled(:integer)
    required(:cultivar_id).filled(:integer)
    optional(:allow_cultivar_mixing).maybe(:bool)
  end

  ProductionRunChangeSchema = Dry::Schema.Params do
    required(:production_run_id).filled(:integer)
  end

  ProductionRunOrchardChangeSchema = Dry::Schema.Params do
    required(:reworks_run_type_id).filled(:integer)
    required(:production_run_id).filled(:integer)
    required(:orchard_id).filled(:integer)
  end

  ReworksRunChangeRunOrchardSchema = Dry::Schema.Params do
    required(:reworks_run_type_id).filled(:integer)
    required(:production_run_id).filled(:integer)
    required(:orchard_id).filled(:integer)
    optional(:allow_orchard_mixing).maybe(:bool)
    optional(:allow_cultivar_mixing).maybe(:bool)
    optional(:allow_cultivar_group_mixing).maybe(:bool)
  end

  DeliveryChangeSchema = Dry::Schema.Params do
    required(:reworks_run_type_id).filled(:integer)
    required(:from_delivery_id).filled(:integer)
    required(:to_delivery_id).filled(:integer)
  end
end
