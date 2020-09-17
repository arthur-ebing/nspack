# frozen_string_literal: true

module MasterfilesApp
  CustomerVarietySchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:variety_as_customer_variety_id).filled(:integer)
    required(:packed_tm_group_id).filled(:integer)
  end
end
