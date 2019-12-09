# frozen_string_literal: true

module MasterfilesApp
  DepotSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:city_id, :integer).maybe(:int?)
    required(:depot_code, Types::StrippedString).filled(:str?)
    required(:description, Types::StrippedString).maybe(:str?)
    required(:edi_hub_address, Types::StrippedString).maybe(:str?)
  end
end
