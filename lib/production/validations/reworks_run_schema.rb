# frozen_string_literal: true

module ProductionApp
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
    optional(:make_changes, :bool).maybe(:bool?)
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
end
