# frozen_string_literal: true

module MasterfilesApp
  OrganizationSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    optional(:parent_id, :integer).maybe(:int?)
    required(:short_description, Types::StrippedString).filled(:str?)
    required(:medium_description, Types::StrippedString).filled(:str?)
    required(:long_description, Types::StrippedString).maybe(:str?)
    required(:vat_number, Types::StrippedString).maybe(:str?)
    required(:role_ids, Types::IntArray).filled { each(:int?) }
  end
end
