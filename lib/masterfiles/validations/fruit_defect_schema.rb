# frozen_string_literal: true

module MasterfilesApp
  FruitDefectSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:rmt_class_id).filled(:integer)
    required(:fruit_defect_type_id).filled(:integer)
    required(:fruit_defect_code).filled(Types::StrippedString)
    required(:short_description).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:internal).maybe(:bool)
  end
end
