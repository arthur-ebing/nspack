# frozen_string_literal: true

module MasterfilesApp
  FarmSectionSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:farm_manager_party_role_id, :integer).filled(:int?)
    required(:farm_section_name, Types::StrippedString).filled(:str?)
    required(:description, Types::StrippedString).maybe(:str?)
  end
end
