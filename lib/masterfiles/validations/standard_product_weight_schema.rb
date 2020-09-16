# frozen_string_literal: true

module MasterfilesApp
  StandardProductWeightSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:commodity_id, :integer).filled(:int?)
    required(:standard_pack_id, :integer).filled(:int?)
    required(:gross_weight, :decimal).filled(:decimal?)
    required(:nett_weight, :decimal).filled(:decimal?)
    required(:standard_carton_nett_weight, %i[nil decimal]).maybe(:decimal?)
    optional(:ratio_to_standard_carton, %i[nil decimal]).maybe(:decimal?)
    required(:is_standard_carton, :bool).maybe(:bool?)
  end
end
