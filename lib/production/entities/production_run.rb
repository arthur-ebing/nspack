# frozen_string_literal: true

module ProductionApp
  class ProductionRun < Dry::Struct
    attribute :id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :puc_id, Types::Integer
    attribute :packhouse_resource_id, Types::Integer
    attribute :production_line_id, Types::Integer
    attribute :season_id, Types::Integer
    attribute :orchard_id, Types::Integer
    attribute :cultivar_group_id, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :product_setup_template_id, Types::Integer
    attribute :cloned_from_run_id, Types::Integer
    attribute :active_run_stage, Types::String
    attribute :started_at, Types::DateTime
    attribute :closed_at, Types::DateTime
    attribute :re_executed_at, Types::DateTime
    attribute :completed_at, Types::DateTime
    attribute :allow_cultivar_mixing, Types::Bool
    attribute :allow_orchard_mixing, Types::Bool
    attribute :reconfiguring, Types::Bool
    attribute :closed, Types::Bool
    attribute :setup_complete, Types::Bool
    attribute :completed, Types::Bool
    attribute :running, Types::Bool
    attribute :tipping, Types::Bool
    attribute :labeling, Types::Bool
    attribute :allow_cultivar_group_mixing, Types::Bool
    attribute? :active, Types::Bool
    attribute? :allocation_required, Types::Bool
    attribute :legacy_data, Types::Hash.optional
    attribute :legacy_bintip_criteria, Types::Hash.optional
    attribute :colour_percentage_id, Types::Integer
    attribute :actual_cold_treatment_id, Types::Integer
    attribute :actual_ripeness_treatment_id, Types::Integer
    attribute :rmt_code_id, Types::Integer
    attribute :rmt_size_id, Types::Integer
    attribute :rmt_class_id, Types::Integer
    attribute :run_batch_number, Types::String

    def next_stage
      if tipping && labeling
        :labeling
      elsif tipping
        :labeling
      elsif labeling
        :complete
      else
        :tipping
      end
    end
  end

  class ProductionRunFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :puc_id, Types::Integer
    attribute :packhouse_resource_id, Types::Integer
    attribute :production_line_id, Types::Integer
    attribute :season_id, Types::Integer
    attribute :orchard_id, Types::Integer
    attribute :cultivar_group_id, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :product_setup_template_id, Types::Integer
    attribute :cloned_from_run_id, Types::Integer
    attribute :active_run_stage, Types::String
    attribute :started_at, Types::DateTime
    attribute :closed_at, Types::DateTime
    attribute :re_executed_at, Types::DateTime
    attribute :completed_at, Types::DateTime
    attribute :allow_cultivar_mixing, Types::Bool
    attribute :allow_orchard_mixing, Types::Bool
    attribute :reconfiguring, Types::Bool
    attribute :closed, Types::Bool
    attribute :setup_complete, Types::Bool
    attribute :completed, Types::Bool
    attribute :running, Types::Bool
    attribute :tipping, Types::Bool
    attribute :labeling, Types::Bool
    attribute? :active, Types::Bool
    attribute? :allocation_required, Types::Bool
    attribute :template_name, Types::String
    attribute :production_run_code, Types::String
    attribute :cloned_from_run_code, Types::String
    attribute :cultivar_group_code, Types::String
    attribute :cultivar_name, Types::String
    attribute :farm_code, Types::String
    attribute :puc_code, Types::String
    attribute :orchard_code, Types::String
    attribute :season_code, Types::String
    attribute :commodity_code, Types::String
    attribute :packhouse_code, Types::String
    attribute :line_code, Types::String
    attribute :status, Types::String
    attribute :allow_cultivar_group_mixing, Types::Bool
    attribute :legacy_data, Types::Hash.optional
    attribute :legacy_bintip_criteria, Types::Hash.optional
    attribute :colour_percentage_id, Types::Integer
    attribute :actual_cold_treatment_id, Types::Integer
    attribute :actual_ripeness_treatment_id, Types::Integer
    attribute :rmt_code_id, Types::Integer
    attribute :rmt_size_id, Types::Integer
    attribute :rmt_class_id, Types::Integer
    attribute :size_code, Types::String
    attribute :rmt_code, Types::String
    attribute :colour_percentage, Types::String
    attribute :actual_cold_treatment_code, Types::String
    attribute :actual_ripeness_treatment_code, Types::String
    attribute :class_code, Types::String
    attribute :run_batch_number, Types::String
  end
end
