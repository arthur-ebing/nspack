# frozen_string_literal: true

module ProductionApp
  ShiftExceptionSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:shift_id, :integer).filled(:int?)
    required(:contract_worker_id, :integer).filled(:int?)
    required(:remarks, Types::StrippedString).maybe(:str?)
    required(:running_hours, :decimal).maybe(:decimal?)
  end
end
