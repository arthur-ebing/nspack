# frozen_string_literal: true

module ProductionApp
  ProductResourceAllocationSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:production_run_id, :integer).filled(:int?)
    required(:plant_resource_id, :integer).filled(:int?)
    required(:product_setup_id, :integer).maybe(:int?)
    required(:label_template_id, :integer).maybe(:int?)
    required(:packing_method_id, :integer).filled(:int?)
  end

  ProductResourceAllocationSelectSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:product_setup_id, :integer).maybe(:int?)
    required(:label_template_id, :integer).maybe(:int?)
    required(:packing_method_id, :integer).filled(:int?)
  end
end
