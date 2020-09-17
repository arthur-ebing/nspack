# frozen_string_literal: true

module MasterfilesApp
  PmBomsProductSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:pm_product_id).filled(:integer)
    required(:pm_bom_id).filled(:integer)
    required(:uom_id).filled(:integer)
    required(:quantity).filled(:decimal)
  end
end
