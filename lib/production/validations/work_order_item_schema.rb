# frozen_string_literal: true

module ProductionApp
  WorkOrderItemSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    optional(:work_order_id).filled(:integer)
    optional(:product_setup_id).filled(:integer)
    required(:carton_qty_required).maybe(:integer)
    optional(:carton_qty_produced).maybe(:integer)
    optional(:completed).maybe(:bool)
    optional(:completed_at).maybe(:time)
  end
end
