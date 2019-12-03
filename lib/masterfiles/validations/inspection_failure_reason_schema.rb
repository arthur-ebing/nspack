# frozen_string_literal: true

module MasterfilesApp
  InspectionFailureReasonSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:inspection_failure_type_id, :integer).filled(:int?)
    required(:failure_reason, Types::StrippedString).filled(:str?)
    required(:description, Types::StrippedString).maybe(:str?)
    required(:main_factor, :bool).maybe(:bool?)
    required(:secondary_factor, :bool).maybe(:bool?)
  end
end
