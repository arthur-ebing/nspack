# frozen_string_literal: true

module MasterfilesApp
  StandardProductWeightSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:commodity_id, :integer).filled(:int?)
    required(:standard_pack_id, :integer).filled(:int?)
    required(:gross_weight, :decimal).filled(:decimal?)
    required(:nett_weight, :decimal).filled(:decimal?)
  end
end
