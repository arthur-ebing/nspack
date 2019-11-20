# frozen_string_literal: true

module ProductionApp
  ProductionRunNewSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:farm_id, :integer).filled(:int?)
    required(:puc_id, :integer).filled(:int?)
    required(:packhouse_resource_id, :integer).filled(:int?)
    required(:production_line_id, :integer).filled(:int?)
    required(:season_id, :integer).filled(:int?)
    required(:orchard_id, :integer).maybe(:int?)
    required(:cultivar_group_id, :integer).maybe(:int?)
    required(:cultivar_id, :integer).maybe(:int?)
    optional(:product_setup_template_id, :integer).maybe(:int?)
    required(:allow_cultivar_mixing, :bool).maybe(:bool?)
    required(:allow_orchard_mixing, :bool).maybe(:bool?)
  end

  ProductionRunSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:farm_id, :integer).filled(:int?)
    required(:puc_id, :integer).filled(:int?)
    required(:season_id, :integer).filled(:int?)
    required(:orchard_id, :integer).maybe(:int?)
    required(:cultivar_group_id, :integer).maybe(:int?)
    required(:cultivar_id, :integer).maybe(:int?)
    optional(:product_setup_template_id, :integer).maybe(:int?)
    optional(:cloned_from_run_id, :integer).maybe(:int?)
    optional(:active_run_stage, Types::StrippedString).maybe(:str?)
    optional(:started_at, :date_time).maybe(:time?)
    optional(:closed_at, :date_time).maybe(:time?)
    optional(:re_executed_at, :date_time).maybe(:time?)
    optional(:completed_at, :date_time).maybe(:time?)
    required(:allow_cultivar_mixing, :bool).maybe(:bool?)
    required(:allow_orchard_mixing, :bool).maybe(:bool?)
    optional(:reconfiguring, :bool).maybe(:bool?)
    optional(:running, :bool).maybe(:bool?)
    optional(:tipping, :bool).maybe(:bool?)
    optional(:labeling, :bool).maybe(:bool?)
    optional(:closed, :bool).maybe(:bool?)
    optional(:setup_complete, :bool).maybe(:bool?)
    optional(:completed, :bool).maybe(:bool?)
  end

  ProductionRunTemplateSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:product_setup_template_id, :integer).filled(:int?)
  end
end
