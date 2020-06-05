# frozen_string_literal: true

module ProductionApp  # rubocop:disable Metrics/ModuleLength
  ReworksRunSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:user, Types::StrippedString).filled(:str?)
    required(:reworks_run_type_id, :integer).filled(:int?)
    optional(:remarks, Types::StrippedString).maybe(:str?)
    optional(:scrap_reason_id, :integer).maybe(:int?)
    optional(:pallets_selected, :array).maybe(:array?) { each(:str?) }
    optional(:pallets_affected, :array).maybe(:array?) { each(:str?) }
    optional(:changes_made, :hash).maybe(:hash?)
    optional(:pallets_scrapped, :array).maybe(:array?) { each(:str?) }
    optional(:pallets_unscrapped, :array).maybe(:array?) { each(:str?) }
  end

  ReworksRunNewSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:reworks_run_type_id, :integer).filled(:int?)
    required(:pallets_selected, :array).filled(:array?) { each(:str?) }
    optional(:make_changes, :bool).maybe(:bool?)
  end

  ReworksRunScrapPalletsSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:reworks_run_type_id, :integer).filled(:int?)
    required(:scrap_reason_id, :integer).filled(:int?)
    required(:remarks, Types::StrippedString).filled(:str?)
    required(:pallets_selected, :array).filled(:array?) { each(:str?) }
    optional(:make_changes, :bool).maybe(:bool?)
  end

  ReworksRunFlatSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:user, Types::StrippedString).filled(:str?)
    required(:reworks_run_type_id, :integer).filled(:int?)
    optional(:remarks, Types::StrippedString).maybe(:str?)
    optional(:scrap_reason_id, :integer).maybe(:int?)
    required(:pallets_selected, :array).filled(:array?) { each(:str?) }
    optional(:pallets_affected, :array).maybe(:array?) { each(:str?) }
    optional(:changes_made, :hash).maybe(:hash?)
    optional(:pallets_scrapped, :array).maybe(:array?) { each(:str?) }
    optional(:pallets_unscrapped, :array).maybe(:array?) { each(:str?) }
    optional(:pallet_sequence_id, :integer).maybe(:int?)
    optional(:affected_sequences, :array).maybe(:array?) { each(:int?) }
    optional(:make_changes, :bool).maybe(:bool?)
    required(:allow_cultivar_group_mixing, :bool).maybe(:bool?)
  end

  ReworksRunTipBinsSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:reworks_run_type_id, :integer).filled(:int?)
    required(:production_run_id, :integer).filled(:int?)
    required(:pallets_selected, :array).filled(:array?) { each(:str?) }
    optional(:make_changes, :bool).maybe(:bool?)
    required(:allow_cultivar_mixing, :bool).maybe(:bool?)
    required(:gross_weight, :decimal).maybe(:decimal?)
  end

  ReworksRunPrintBarcodeSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:printer, :integer).filled(:int?)
    required(:label_template_id, :integer).filled(:int?)
    required(:no_of_prints, :integer).filled(:int?, gt?: 0)
    required(:pallet_number, Types::StrippedString).maybe(:str?)
    required(:pallet_sequence_id, :integer).maybe(:int?)
  end

  ProductionRunUpdateSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:pallet_sequence_id, :integer).filled(:int?)
    required(:production_run_id, :integer).filled(:int?)
    required(:old_production_run_id, :integer).filled(:int?)
    required(:reworks_run_type_id, :integer).filled(:int?)
    optional(:allow_cultivar_group_mixing, :bool).maybe(:bool?)
  end

  ProductionRunUpdateFarmDetailsSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:pallet_sequence_id, :integer).filled(:int?)
    required(:reworks_run_type_id, :integer).filled(:int?)
    required(:farm_id, :integer).filled(:int?)
    required(:puc_id, :integer).filled(:int?)
    required(:orchard_id, :integer).maybe(:int?)
    required(:cultivar_group_id, :integer).filled(:int?)
    required(:cultivar_id, :integer).maybe(:int?)
    required(:season_id, :integer).filled(:int?)
  end

  ReworksRunUpdateGrossWeightSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:reworks_run_type_id, :integer).filled(:int?)
    required(:pallet_number, Types::StrippedString).maybe(:str?)
    required(:standard_pack_code_id, :integer).filled(:int?)
    required(:gross_weight, :decimal).filled(:decimal?)
  end

  SequenceSetupDataSchema = Dry::Validation.Params do # rubocop:disable Metrics/BlockLength
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:marketing_variety_id, :integer).filled(:int?)
    required(:customer_variety_id, :integer).maybe(:int?)
    required(:std_fruit_size_count_id, :integer).maybe(:int?)
    required(:basic_pack_code_id, :integer).filled(:int?)
    required(:standard_pack_code_id, :integer).filled(:int?)
    required(:fruit_actual_counts_for_pack_id, :integer).maybe(:int?)
    required(:fruit_size_reference_id, :integer).maybe(:int?)
    required(:marketing_org_party_role_id, :integer).filled(:int?)
    required(:packed_tm_group_id, :integer).filled(:int?)
    required(:mark_id, :integer).filled(:int?)
    required(:inventory_code_id, :integer).maybe(:int?)
    required(:pallet_format_id, :integer).filled(:int?)
    required(:cartons_per_pallet_id, :integer).filled(:int?)
    required(:pm_bom_id, :integer).maybe(:int?)
    # required(:extended_columns, :hash).maybe(:hash?)
    required(:client_size_reference, Types::StrippedString).maybe(:str?)
    required(:client_product_code, Types::StrippedString).maybe(:str?)
    optional(:treatment_ids, Types::IntArray).maybe { each(:int?) }
    required(:marketing_order_number, Types::StrippedString).maybe(:str?)
    required(:sell_by_code, Types::StrippedString).maybe(:str?)
    required(:pallet_label_name, Types::StrippedString).maybe(:str?)
    required(:grade_id, :integer).maybe(:int?)
    required(:product_chars, Types::StrippedString).maybe(:str?)
    required(:pm_type_id, :integer).maybe(:int?)
    required(:pm_subtype_id, :integer).maybe(:int?)
  end

  ReworksRunUpdatePalletSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:reworks_run_type_id, :integer).filled(:int?)
    required(:pallet_number, Types::StrippedString).maybe(:str?)
    required(:fruit_sticker_pm_product_id, :integer).filled(:int?)
    required(:fruit_sticker_pm_product_2_id, :integer).maybe(:int?)
  end

  EditCartonQuantitySchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:column_value, :integer).filled(:int?, gt?: 0)
  end

  ManuallyWeighRmtBinSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:reworks_run_type_id, :integer).filled(:int?)
    required(:bin_number, Types::StrippedString).maybe(:str?)
    required(:gross_weight, :decimal).filled(:decimal?)
    required(:measurement_unit, Types::StrippedString).maybe(:str?)
  end

  ChangeDeliveriesOrchardSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:to_orchard, :integer).filled(:int?)
    optional(:from_cultivar, :integer)
    required(:from_orchard, :integer).filled(:int?)
    required(:to_cultivar, :integer).filled(:int?)
  end

  FromCultivarSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:from_cultivar, :integer).filled(:int?)
  end

  ChangeCultivarOnlyCultivarSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:allow_cultivar_mixing, :bool).filled(:bool?)
  end

  ReworksRunBulkProductionRunUpdateSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:reworks_run_type_id, :integer).filled(:int?)
    required(:pallets_selected, :array).maybe(:array?) { each(:str?) }
    required(:from_production_run_id, :integer).filled(:int?)
    required(:to_production_run_id, :integer).filled(:int?)
    optional(:make_changes, :bool).maybe(:bool?)
    optional(:allow_cultivar_group_mixing, :bool).maybe(:bool?)
  end

  ReworksBulkWeighBinsSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:reworks_run_type_id, :integer).filled(:int?)
    required(:pallets_selected, :array).filled(:array?) { each(:str?) }
    optional(:make_changes, :bool).maybe(:bool?)
    required(:gross_weight, :decimal).filled(:decimal?)
    required(:avg_gross_weight, :bool).maybe(:bool?)
  end

  ReworksOrchardChangeSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:delivery_ids, :array).filled(:array?) { each(:int?) }
    required(:from_orchard, :integer).filled(:int?)
    required(:from_cultivar, :integer).maybe(:int?)
    required(:to_orchard, :integer).filled(:int?)
    required(:to_cultivar, :integer).filled(:int?)
    required(:allow_cultivar_mixing, :bool).maybe(:bool?)
    required(:ignore_runs_that_allow_mixing, :bool).maybe(:bool?)
  end
end
