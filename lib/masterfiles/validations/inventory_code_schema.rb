# frozen_string_literal: true

module MasterfilesApp
  InventoryCodeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:inventory_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:edi_out_inventory_code).maybe(Types::StrippedString)
    required(:fruit_item_incentive_rate).maybe(:decimal)
  end
end
