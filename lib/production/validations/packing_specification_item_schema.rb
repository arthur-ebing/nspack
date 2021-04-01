# frozen_string_literal: true

module ProductionApp
  PackingSpecificationItemSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:description).maybe(Types::StrippedString)
    required(:pm_bom_id).maybe(:integer)
    required(:pm_mark_id).maybe(:integer)
    required(:product_setup_id).filled(:integer)
    required(:tu_labour_product_id).maybe(:integer)
    required(:ru_labour_product_id).maybe(:integer)
    required(:ri_labour_product_id).maybe(:integer)
    required(:fruit_sticker_ids).maybe(:array).each(:integer) # OR: maybe(:array).maybe { each(:integer) } # if param can be nil (not [])
    required(:tu_sticker_ids).maybe(:array).each(:integer) # OR: maybe(:array).maybe { each(:integer) } # if param can be nil (not [])
    required(:ru_sticker_ids).maybe(:array).each(:integer) # OR: maybe(:array).maybe { each(:integer) } # if param can be nil (not [])
  end
end
