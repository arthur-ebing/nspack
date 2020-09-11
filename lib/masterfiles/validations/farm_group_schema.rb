# frozen_string_literal: true

module MasterfilesApp
  FarmGroupSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:owner_party_role_id).filled(:integer)
    required(:farm_group_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
