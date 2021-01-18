# frozen_string_literal: true

module MasterfilesApp
  PmBomSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:bom_code).filled(Types::StrippedString)
    required(:erp_bom_code).maybe(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:label_description).maybe(Types::StrippedString)
    optional(:system_code).maybe(Types::StrippedString)
    required(:gross_weight).maybe(:decimal)
    required(:nett_weight).maybe(:decimal)
  end

  PmBomSubtypeSchema = Dry::Schema.Params do
    required(:pm_subtype_ids).filled(:array).maybe { each(:integer) }
  end
end
