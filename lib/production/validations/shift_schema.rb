# frozen_string_literal: true

module ProductionApp
  ShiftSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:shift_type_id).filled(:integer)
    required(:date).filled(:date)
    # required(:running_hours).maybe(:decimal)
    # required(:start_date_time).maybe(:time)
    # required(:end_date_time).maybe(:time)
  end

  UpdateShiftSchema = Dry::Schema.Params do
    required(:id).filled(:integer)
    required(:shift_type_id).filled(:integer)
    required(:running_hours).maybe(:decimal)
    required(:start_date_time).maybe(:time)
    required(:end_date_time).maybe(:time)
  end
end
