# frozen_string_literal: true

module ProductionApp
  PalletMixRuleSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:scope).filled(Types::StrippedString)
    optional(:production_run_id).maybe(:integer)
    optional(:packhouse_plant_resource_id).maybe(:integer)
    optional(:pallet_id).maybe(:integer)
    optional(:allow_tm_mix).maybe(:bool)
    optional(:allow_grade_mix).maybe(:bool)
    optional(:allow_size_ref_mix).maybe(:bool)
    optional(:allow_pack_mix).maybe(:bool)
    optional(:allow_std_count_mix).maybe(:bool)
    optional(:allow_mark_mix).maybe(:bool)
    optional(:allow_inventory_code_mix).maybe(:bool)
    optional(:allow_cultivar_mix).maybe(:bool)
    optional(:allow_cultivar_group_mix).maybe(:bool)
    optional(:allow_puc_mix).maybe(:bool)
    optional(:allow_orchard_mix).maybe(:bool)
  end
end
