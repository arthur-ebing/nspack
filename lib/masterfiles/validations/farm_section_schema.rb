# frozen_string_literal: true

module MasterfilesApp
  FarmSectionSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:farm_id).filled(:integer)
    required(:farm_manager_party_role_id).filled(:integer)
    required(:farm_section_name).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
