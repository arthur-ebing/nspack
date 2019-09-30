# frozen_string_literal: true

module MasterfilesApp
  PortSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:port_type_id, :integer).filled(:int?)
    required(:voyage_type_id, :integer).filled(:int?)
    required(:port_code, Types::StrippedString).filled(:str?)
    required(:description, Types::StrippedString).maybe(:str?)
  end
end
