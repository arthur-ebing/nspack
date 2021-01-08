# frozen_string_literal: true

module MasterfilesApp
  SupplierSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:supplier_party_role_id).filled(:integer)
    required(:supplier_group_ids).maybe(:array).each(:integer)
    required(:farm_ids).maybe(:array).each(:integer)
  end

  CreateSupplierSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:supplier_party_role_id).filled(:string)
    optional(:supplier_group_ids).maybe(:array).each(:integer)
    required(:farm_ids).maybe(:array).each(:integer)

    optional(:short_description).maybe(Types::StrippedString)
    optional(:medium_description).maybe(Types::StrippedString)
    optional(:long_description).maybe(Types::StrippedString)
    optional(:vat_number).maybe(Types::StrippedString)
    optional(:company_reg_no).maybe(Types::StrippedString)
  end
end
