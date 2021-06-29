# frozen_string_literal: true

module SecurityApp
  class RegisteredMobileDevice < Dry::Struct
    attribute :id, Types::Integer
    attribute :ip_address, Types::String
    attribute :start_page_program_function_id, Types::Integer
    attribute :active, Types::Bool
    attribute :scan_with_camera, Types::Bool
    attribute :start_page, Types::String
    attribute :hybrid_device, Types::Bool
    attribute :act_as_system_resource_id, Types::Integer
    attribute :act_as_reader_id, Types::String
    attribute :act_as_system_resource_code, Types::String

    def act_as_robot
      return nil if act_as_system_resource_id.nil?

      "#{act_as_system_resource_id}_#{act_as_reader_id || '1'}"
    end
  end
end
