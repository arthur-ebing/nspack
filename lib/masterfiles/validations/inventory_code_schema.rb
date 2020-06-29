# frozen_string_literal: true

module MasterfilesApp
  InventoryCodeSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:inventory_code, Types::StrippedString).filled(:str?)
    required(:description, Types::StrippedString).maybe(:str?)
    required(:edi_out_inventory_code, Types::StrippedString).maybe(:str?)
    required(:fruit_item_incentive_rate, :decimal).maybe(:decimal?)
  end
end
