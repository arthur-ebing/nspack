# frozen_string_literal: true

module ProductionApp
  class PalletMixRule < Dry::Struct
    attribute :id, Types::Integer
    attribute :scope, Types::String
    attribute :production_run_id, Types::Integer
    attribute :packhouse_plant_resource_id, Types::Integer
    attribute :pallet_id, Types::Integer
    attribute :allow_tm_mix, Types::Bool
    attribute :allow_grade_mix, Types::Bool
    attribute :allow_size_ref_mix, Types::Bool
    attribute :allow_pack_mix, Types::Bool
    attribute :allow_std_count_mix, Types::Bool
    attribute :allow_mark_mix, Types::Bool
    attribute :allow_inventory_code_mix, Types::Bool
    attribute :allow_cultivar_mix, Types::Bool
    attribute :allow_cultivar_group_mix, Types::Bool
    attribute :allow_puc_mix, Types::Bool
    attribute :allow_orchard_mix, Types::Bool
    attribute :allow_variety_mix, Types::Bool
    attribute :allow_marketing_org_mix, Types::Bool
    attribute :allow_sell_by_mix, Types::Bool
  end

  class PalletMixRuleFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :scope, Types::String
    attribute :production_run_id, Types::Integer
    attribute :packhouse_plant_resource_id, Types::Integer
    attribute :pallet_id, Types::Integer
    attribute :allow_tm_mix, Types::Bool
    attribute :allow_grade_mix, Types::Bool
    attribute :allow_size_ref_mix, Types::Bool
    attribute :allow_pack_mix, Types::Bool
    attribute :allow_std_count_mix, Types::Bool
    attribute :allow_mark_mix, Types::Bool
    attribute :allow_inventory_code_mix, Types::Bool
    attribute :allow_cultivar_mix, Types::Bool
    attribute :allow_cultivar_group_mix, Types::Bool
    attribute :allow_puc_mix, Types::Bool
    attribute :allow_orchard_mix, Types::Bool
    attribute :packhouse_code, Types::String
    attribute :allow_variety_mix, Types::Bool
    attribute :allow_marketing_org_mix, Types::Bool
    attribute :allow_sell_by_mix, Types::Bool
  end
end
