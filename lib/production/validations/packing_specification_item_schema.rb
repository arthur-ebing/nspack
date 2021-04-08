# frozen_string_literal: true

module ProductionApp
  PackingSpecificationItemSchema = Dry::Schema.Params do
    optional(:description).maybe(Types::StrippedString)
    required(:pm_bom_id).maybe(:integer)
    required(:pm_mark_id).maybe(:integer)
    required(:product_setup_id).filled(:integer)
    optional(:tu_labour_product_id).maybe(:integer)
    optional(:ru_labour_product_id).maybe(:integer)
    optional(:ri_labour_product_id).maybe(:integer)
    optional(:fruit_sticker_ids).maybe(:array).each(:integer) # OR: maybe(:array).maybe { each(:integer) } # if param can be nil (not [])
    optional(:tu_sticker_ids).maybe(:array).each(:integer) # OR: maybe(:array).maybe { each(:integer) } # if param can be nil (not [])
    optional(:ru_sticker_ids).maybe(:array).each(:integer) # OR: maybe(:array).maybe { each(:integer) } # if param can be nil (not [])
  end
end
