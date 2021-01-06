# frozen_string_literal: true

module MasterfilesApp
  SupplierSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:supplier_party_role_id).filled(:integer)
    required(:supplier_group_ids).maybe(:array).each(:integer)
    required(:farm_ids).maybe(:array).each(:integer)
  end
end
