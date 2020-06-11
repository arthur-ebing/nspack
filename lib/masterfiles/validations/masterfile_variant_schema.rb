# frozen_string_literal: true

module MasterfilesApp
  MasterfileVariantSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    optional(:masterfile_table, Types::StrippedString).filled(:str?)
    required(:variant_code, Types::StrippedString).filled(:str?)
    optional(:masterfile_id, :integer).filled(:int?)
  end
end
