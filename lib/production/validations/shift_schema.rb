# frozen_string_literal: true

module ProductionApp
  ShiftSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:shift_type_id, :integer).filled(:int?)
    required(:date, :date).filled(:date?)
    # required(:running_hours, %i[nil decimal]).maybe(:decimal?)
    # required(:start_date_time, %i[nil time]).maybe(:time?)
    # required(:end_date_time, %i[nil time]).maybe(:time?)
  end
end
