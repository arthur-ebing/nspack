# frozen_string_literal: true

module MasterfilesApp
  RmtContainerTypeSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    optional(:active, :bool).filled(:bool?)
    required(:container_type_code, Types::StrippedString).filled(:str?)
    required(:description, Types::StrippedString).maybe(:str?)
    optional(:rmt_inner_container_type_id, :integer).maybe(:int?)
    required(:tare_weight, :decimal).maybe(:decimal?)
  end
end
