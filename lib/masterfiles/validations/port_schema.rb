# frozen_string_literal: true

module MasterfilesApp
  PortSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:port_type_id, :integer).filled(:int?)
    required(:voyage_type_id, :integer).filled(:int?)
    optional(:city_id, :integer).maybe(:int?)
    required(:port_code, Types::StrippedString).filled(:str?)
    required(:description, Types::StrippedString).maybe(:str?)

    validate(filled?: %i[port_type_id city_id]) do |port_type_id, city_id|
      port_type_code = MasterfilesApp::PortTypeRepo.new.find_port_type(port_type_id)&.port_type_code
      port_type_code != AppConst::PORT_TYPE_POD || !city_id.nil_or_empty?
    end
  end
end
