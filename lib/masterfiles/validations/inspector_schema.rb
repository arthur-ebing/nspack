# frozen_string_literal: true

module MasterfilesApp
  InspectorSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:inspector_party_role_id, :integer).filled(:int?)
    required(:tablet_ip_address, Types::StrippedString).filled(:str?)
    required(:tablet_port_number, :integer).maybe(:int?)
    required(:inspector_code, Types::StrippedString).filled(:str?)
  end

  InspectorFlatSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:surname, Types::StrippedString).filled(:str?)
    required(:first_name, Types::StrippedString).filled(:str?)
    required(:title, Types::StrippedString).filled(:str?)
    required(:vat_number, Types::StrippedString).maybe(:str?)
    required(:role_ids, Types::IntArray).filled { each(:int?) }
    required(:inspector_party_role_id, :integer).filled(:int?)
    required(:tablet_ip_address, Types::StrippedString).filled(:str?)
    required(:tablet_port_number, :integer).maybe(:int?)
    required(:inspector_code, Types::StrippedString).filled(:str?)
  end
end
