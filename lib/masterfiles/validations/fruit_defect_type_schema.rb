# frozen_string_literal: true

module MasterfilesApp
  FruitDefectTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:fruit_defect_type_name).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:fruit_defect_category_id).maybe(:integer)
    required(:reporting_description).maybe(Types::StrippedString)
  end
end
