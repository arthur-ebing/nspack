# frozen_string_literal: true

module ProductionApp
  ShiftExceptionSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:shift_id).filled(:integer)
    required(:contract_worker_id).filled(:integer)
    required(:remarks).maybe(Types::StrippedString)
    required(:running_hours).maybe(:decimal)
  end
end
