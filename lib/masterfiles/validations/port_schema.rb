# frozen_string_literal: true

module MasterfilesApp
  PortSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:port_type_ids, Types::IntArray).filled { each(:int?) }
    required(:voyage_type_ids, Types::IntArray).filled { each(:int?) }
    optional(:city_id, :integer).maybe(:int?)
    required(:port_code, Types::StrippedString).filled(:str?)
    required(:description, Types::StrippedString).maybe(:str?)
  end
end
