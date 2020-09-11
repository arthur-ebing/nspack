# frozen_string_literal: true

module MasterfilesApp
  StandardProductWeightSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:commodity_id).filled(:integer)
    required(:standard_pack_id).filled(:integer)
    required(:gross_weight).filled(:decimal)
    required(:nett_weight).filled(:decimal)
    required(:standard_carton_nett_weight).maybe(:decimal)
    optional(:ratio_to_standard_carton).maybe(:decimal)
    required(:is_standard_carton).maybe(:bool)
  end
end
