# frozen_string_literal: true

module EdiApp
  EdiOutRuleDestSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:destination_type, Types::StrippedString).filled(:str?)
  end

  EdiOutRuleDepotSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:flow_type, Types::StrippedString).filled(:str?)
    required(:destination_type, Types::StrippedString).filled(:str?)
    required(:depot_id, :integer).filled(:int?)
    required(:hub_address, Types::StrippedString).filled(:str?)
    required(:directory_keys, :array).filled(:array?) { each(:str?) }
  end

  EdiOutRulePartyRoleSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:flow_type, Types::StrippedString).filled(:str?)
    required(:role_id, :integer).filled(:str?)
    required(:party_role_id, :integer).filled(:int?)
    required(:hub_address, Types::StrippedString).filled(:str?)
    required(:directory_keys, :array).filled(:array?) { each(:str?) }
  end
end
