# frozen_string_literal: true

module MasterfilesApp
  TargetMarketSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:target_market_name).filled(Types::StrippedString)
    optional(:country_ids).maybe(:array).each(:integer)
    required(:tm_group_ids).filled(:array).each(:integer)
    required(:description).maybe(Types::StrippedString)
    required(:inspection_tm).maybe(:bool)
    optional(:target_customer_ids).maybe(:array).each(:integer)
    required(:protocol_exception).maybe(:bool)
  end
end
