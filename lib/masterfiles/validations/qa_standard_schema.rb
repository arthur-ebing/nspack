# frozen_string_literal: true

module MasterfilesApp
  QaStandardSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:qa_standard_name).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:season_id).filled(:integer)
    required(:qa_standard_type_id).filled(:integer)
    required(:target_market_ids).maybe(:array).each(:integer) # OR: maybe(:array).maybe { each(:integer) } # if param can be nil (not [])
    required(:packed_tm_group_ids).maybe(:array).each(:integer) # OR: maybe(:array).maybe { each(:integer) } # if param can be nil (not [])
    required(:internal_standard).maybe(:bool)
    required(:applies_to_all_markets).maybe(:bool)
  end
end
