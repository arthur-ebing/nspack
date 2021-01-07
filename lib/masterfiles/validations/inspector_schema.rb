# frozen_string_literal: true

module MasterfilesApp
  InspectorSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:inspector_party_role_id).filled(:integer)
    required(:tablet_ip_address).filled(Types::StrippedString)
    required(:tablet_port_number).maybe(:integer)
    required(:inspector_code).filled(Types::StrippedString)
  end

  CreateInspectorSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:party_role_id).filled(:string)
    optional(:surname).maybe(Types::StrippedString)
    optional(:first_name).maybe(Types::StrippedString)
    optional(:title).maybe(Types::StrippedString)
    optional(:vat_number).maybe(Types::StrippedString)
    optional(:tablet_ip_address).maybe(Types::StrippedString)
    optional(:tablet_port_number).maybe(:integer)
    optional(:inspector_code).maybe(Types::StrippedString)
  end
end
