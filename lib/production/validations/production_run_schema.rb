# frozen_string_literal: true

module ProductionApp
  class ProductionRunNewFirstContract < Dry::Validation::Contract
    params do
      required(:packhouse_resource_id).filled(:integer)
      required(:production_line_id).filled(:integer)
      required(:season_id).filled(:integer)
      required(:cultivar_group_id).filled(:integer)
      required(:cultivar_id).maybe(:integer)
      optional(:product_setup_template_id).maybe(:integer)
      required(:allow_cultivar_mixing).maybe(:bool)
      required(:allow_orchard_mixing).maybe(:bool)
      required(:allow_cultivar_group_mixing).maybe(:bool)
    end

    rule(:allow_cultivar_mixing, :cultivar_id) do
      base.failure 'Do not select a cultivar when allowing cultivar mixing.' if values[:cultivar_id] && values[:allow_cultivar_mixing]
      base.failure 'Select a cultivar when not allowing cultivar mixing.' if values[:cultivar_id].nil? && !values[:allow_cultivar_mixing]
    end
  end

  class ProductionRunNewContract < Dry::Validation::Contract
    params do
      required(:farm_id).filled(:integer)
      required(:puc_id).filled(:integer)
      required(:packhouse_resource_id).filled(:integer)
      required(:production_line_id).filled(:integer)
      required(:season_id).filled(:integer)
      required(:orchard_id).maybe(:integer)
      required(:cultivar_group_id).filled(:integer)
      required(:cultivar_id).maybe(:integer)
      optional(:product_setup_template_id).maybe(:integer)
      required(:allow_cultivar_mixing).maybe(:bool)
      required(:allow_orchard_mixing).maybe(:bool)
      required(:allow_cultivar_group_mixing).maybe(:bool)
      optional(:legacy_bintip_criteria).maybe(:hash)
    end
    rule(:allow_cultivar_mixing, :cultivar_id) do
      base.failure 'Do not select a cultivar when allowing cultivar mixing.' if values[:cultivar_id] && values[:allow_cultivar_mixing]
      base.failure 'Select a cultivar when not allowing cultivar mixing.' if values[:cultivar_id].nil? && !values[:allow_cultivar_mixing]
    end
  end

  class ProductionRunContract < Dry::Validation::Contract
    params do
      optional(:id).filled(:integer)
      required(:farm_id).filled(:integer)
      required(:puc_id).filled(:integer)
      required(:season_id).filled(:integer)
      required(:orchard_id).maybe(:integer)
      required(:cultivar_group_id).maybe(:integer)
      required(:cultivar_id).maybe(:integer)
      optional(:product_setup_template_id).maybe(:integer)
      optional(:cloned_from_run_id).maybe(:integer)
      optional(:active_run_stage).maybe(Types::StrippedString)
      optional(:started_at).maybe(:time)
      optional(:closed_at).maybe(:time)
      optional(:re_executed_at).maybe(:time)
      optional(:completed_at).maybe(:time)
      required(:allow_cultivar_mixing).maybe(:bool)
      required(:allow_orchard_mixing).maybe(:bool)
      optional(:reconfiguring).maybe(:bool)
      optional(:running).maybe(:bool)
      optional(:tipping).maybe(:bool)
      optional(:labeling).maybe(:bool)
      optional(:closed).maybe(:bool)
      optional(:setup_complete).maybe(:bool)
      optional(:completed).maybe(:bool)
      required(:allow_cultivar_group_mixing).maybe(:bool)
    end
    rule(:allow_cultivar_mixing, :cultivar_id) do
      base.failure 'Do not select a cultivar when allowing cultivar mixing.' if values[:cultivar_id] && values[:allow_cultivar_mixing]
      base.failure 'Select a cultivar when not allowing cultivar mixing.' if values[:cultivar_id].nil? && !values[:allow_cultivar_mixing]
    end
  end

  class ProductionRunReconfigureContract < Dry::Validation::Contract
    params do
      optional(:id).filled(:integer)
      # required(:farm_id).filled(:integer)
      # required(:puc_id).filled(:integer)
      required(:season_id).filled(:integer)
      # required(:orchard_id).maybe(:integer)
      required(:cultivar_group_id).maybe(:integer)
      required(:cultivar_id).maybe(:integer)
      optional(:product_setup_template_id).maybe(:integer)
      optional(:cloned_from_run_id).maybe(:integer)
      optional(:active_run_stage).maybe(Types::StrippedString)
      optional(:started_at).maybe(:time)
      optional(:closed_at).maybe(:time)
      optional(:re_executed_at).maybe(:time)
      optional(:completed_at).maybe(:time)
      required(:allow_cultivar_mixing).maybe(:bool)
      required(:allow_orchard_mixing).maybe(:bool)
      optional(:reconfiguring).maybe(:bool)
      optional(:running).maybe(:bool)
      optional(:tipping).maybe(:bool)
      optional(:labeling).maybe(:bool)
      optional(:closed).maybe(:bool)
      optional(:setup_complete).maybe(:bool)
      optional(:completed).maybe(:bool)
      required(:allow_cultivar_group_mixing).maybe(:bool)
    end
    rule(:allow_cultivar_mixing, :cultivar_id) do
      base.failure 'Do not select a cultivar when allowing cultivar mixing.' if values[:cultivar_id] && values[:allow_cultivar_mixing]
      base.failure 'Select a cultivar when not allowing cultivar mixing.' if values[:cultivar_id].nil? && !values[:allow_cultivar_mixing]
    end
  end

  ProductionRunTemplateSchema = Dry::Schema.Params do
    required(:product_setup_template_id).filled(:integer)
  end
end
