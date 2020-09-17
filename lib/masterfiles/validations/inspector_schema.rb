# frozen_string_literal: true

module MasterfilesApp
  InspectorSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:inspector_party_role_id).filled(:integer)
    required(:tablet_ip_address).filled(Types::StrippedString)
    required(:tablet_port_number).maybe(:integer)
    required(:inspector_code).filled(Types::StrippedString)
  end

  InspectorPersonSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:surname).filled(Types::StrippedString)
    required(:first_name).filled(Types::StrippedString)
    required(:title).filled(Types::StrippedString)
    required(:vat_number).maybe(Types::StrippedString)
    required(:role_ids).filled(:array).each(:integer)
    required(:tablet_ip_address).filled(Types::StrippedString)
    required(:tablet_port_number).maybe(:integer)
    required(:inspector_code).filled(Types::StrippedString)
  end
end
