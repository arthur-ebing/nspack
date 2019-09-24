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
    attribute? :active, Types::Bool
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
    attribute? :active, Types::Bool
    attribute :template_name, Types::String
    attribute :production_run_code, Types::String
  end
end
