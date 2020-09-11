# frozen_string_literal: true

module EdiApp
  EdiOutRuleDestSchema = Dry::Schema.Params do
    required(:destination_type).filled(Types::StrippedString)
  end

  EdiOutRuleDepotSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:flow_type).filled(Types::StrippedString)
    required(:destination_type).filled(Types::StrippedString)
    required(:depot_id).filled(:integer)
    required(:hub_address).filled(Types::StrippedString)
    # required(:directory_keys, :array).filled(:array?) { each(:str?) }
    required(:directory_keys).filled(:array).each(:string)
  end

  EdiOutRulePartyRoleSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:flow_type).filled(Types::StrippedString)
    required(:role_id).filled(:integer)
    required(:party_role_id).filled(:integer)
    required(:hub_address).filled(Types::StrippedString)
    # required(:directory_keys, :array).filled(:array?) { each(:str?) }
    required(:directory_keys).filled(:array).each(:string)
  end
end
