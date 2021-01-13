# frozen_string_literal: true

module ProductionApp
  PackingSpecificationSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:product_setup_template_id).filled(:integer)
    required(:packing_specification_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
