# frozen_string_literal: true

module ProductionApp
  WorkOrderSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    optional(:marketing_order_id).maybe(:integer)
    required(:start_date).maybe(:date)
    required(:end_date).maybe(:date)
    optional(:completed).maybe(:bool)
    optional(:active).maybe(:bool)
    optional(:completed_at).maybe(:time)
  end
end
