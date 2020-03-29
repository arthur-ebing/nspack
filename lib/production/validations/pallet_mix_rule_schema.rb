# frozen_string_literal: true

module ProductionApp
  PalletMixRuleSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    optional(:scope, Types::StrippedString).maybe(:str?)
    optional(:production_run_id, :integer).maybe(:int?)
    optional(:pallet_id, :integer).maybe(:int?)
    optional(:allow_tm_mix, :bool).maybe(:bool?)
    optional(:allow_grade_mix, :bool).maybe(:bool?)
    optional(:allow_size_ref_mix, :bool).maybe(:bool?)
    optional(:allow_pack_mix, :bool).maybe(:bool?)
    optional(:allow_std_count_mix, :bool).maybe(:bool?)
    optional(:allow_mark_mix, :bool).maybe(:bool?)
    optional(:allow_inventory_code_mix, :bool).maybe(:bool?)
  end
end
