# frozen_string_literal: true

module MasterfilesApp
  TmGroupSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:target_market_group_type_id).filled(:integer)
    required(:target_market_group_name).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:local_tm_group).maybe(:bool)
  end
end
