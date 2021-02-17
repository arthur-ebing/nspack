# frozen_string_literal: true

module ProductionApp
  ProductResourceAllocationSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:production_run_id).filled(:integer)
    required(:plant_resource_id).filled(:integer)
    required(:product_setup_id).maybe(:integer)
    required(:label_template_id).maybe(:integer)
    required(:packing_method_id).filled(:integer)
  end

  ProductResourceAllocationSelectSchema = Dry::Schema.Params do
    required(:product_setup_id).maybe(:integer)
    required(:label_template_id).maybe(:integer)
    required(:packing_method_id).filled(:integer)
    required(:packing_specification_item_id).maybe(:integer)
  end
end
