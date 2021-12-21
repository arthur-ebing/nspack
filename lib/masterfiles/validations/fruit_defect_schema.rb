# frozen_string_literal: true

module MasterfilesApp
  FruitDefectSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:fruit_defect_type_id).filled(:integer)
    required(:fruit_defect_code).filled(Types::StrippedString)
    required(:short_description).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:reporting_description).maybe(Types::StrippedString)
    required(:internal).maybe(:bool)
    required(:external).maybe(:bool)
    required(:pre_harvest).maybe(:bool)
    required(:post_harvest).maybe(:bool)
    required(:severity).filled(Types::StrippedString)
    required(:qc_class_2).maybe(:bool)
    required(:qc_class_3).maybe(:bool)
  end
end
