# frozen_string_literal: true

module MasterfilesApp
  InnerPmMarkSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:inner_pm_mark_code).filled(Types::StrippedString)
    required(:description).filled(Types::StrippedString)
    required(:tu_mark).maybe(:bool)
    required(:ri_mark).maybe(:bool)
    required(:ru_mark).maybe(:bool)
  end
end
