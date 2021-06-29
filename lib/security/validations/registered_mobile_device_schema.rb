# frozen_string_literal: true

module SecurityApp
  RegisteredMobileDeviceSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:ip_address).filled(:string)
    required(:start_page_program_function_id).maybe(:integer)
    optional(:active).filled(:bool)
    required(:scan_with_camera).filled(:bool)
    required(:hybrid_device).filled(:bool)
    # required(:act_as_system_resource_id).maybe(:integer)
    # required(:act_as_reader_id).maybe(Types::StrippedString)
    optional(:act_as_robot).maybe(Types::StrippedString)
  end
end
