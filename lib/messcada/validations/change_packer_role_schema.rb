# frozen_string_literal: true

module MesscadaApp
  ChangePackerRoleSchema = Dry::Schema.Params do
    required(:device).filled(Types::StrippedString)
    required(:identifier).filled(Types::StrippedString)
    required(:role).filled(Types::StrippedString)
    required(:system_resource).value(type?: Dry::Struct)
  end
end
