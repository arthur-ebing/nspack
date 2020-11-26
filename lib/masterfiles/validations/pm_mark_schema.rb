# frozen_string_literal: true

module MasterfilesApp
  PmMarkSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:mark_id).filled(:integer)
    required(:packaging_marks).maybe(:array).maybe { each(:string) }
    required(:description).filled(Types::StrippedString)
  end
end
