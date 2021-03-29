# frozen_string_literal: true

module ProductionApp
  class OrderRepo < BaseRepo
    build_for_select :marketing_orders,
                     label: :order_number,
                     value: :id,
                     no_active_check: true,
                     order_by: :order_number
    build_for_select :work_orders,
                     label: :id,
                     value: :id,
                     order_by: :id
    build_inactive_select :work_orders,
                          label: :id,
                          value: :id,
                          order_by: :id
    build_for_select :work_order_items,
                     label: :id,
                     value: :id,
                     no_active_check: true,
                     order_by: :id

    crud_calls_for :work_order_items, name: :work_order_item, wrapper: WorkOrderItem
    crud_calls_for :work_orders, name: :work_order, wrapper: WorkOrder
    crud_calls_for :marketing_orders, name: :marketing_order, wrapper: MarketingOrder

    def for_select_marketing_orders
      query = <<~SQL
        SELECT order_number || ' - ' || carton_qty_required as custormer_number, id
        FROM marketing_orders
      SQL
      DB[query].select_map(%i[custormer_number id])
    end

    def find_work_order_product_setup_templates(work_order_id)
      DB[:work_order_items]
        .join(:product_setups, id: :product_setup_id)
        .where(Sequel[:work_order_items][:work_order_id] => work_order_id)
        .select_map(:product_setup_template_id).uniq
    end

    def find_product_setups_for_work_order_by_product_setup_templates(work_order_id, product_setup_template_ids)
      DB[:work_order_items]
        .join(:product_setups, id: :product_setup_id)
        .join(:product_setup_templates, id: :product_setup_template_id)
        .where(work_order_id: work_order_id)
        .where(product_setup_template_id: product_setup_template_ids)
        .select_map(:product_setup_id).uniq
    end

    def find_work_order_item_flat(id) # rubocop:disable Metrics/AbcSize
      DB[:work_order_items]
        .join(:product_setups, id: :product_setup_id)
        .join(:product_setup_templates, id: :product_setup_template_id)
        .join(:work_orders, id: Sequel[:work_order_items][:work_order_id])
        .left_join(:marketing_orders, id: :marketing_order_id)
        .where(Sequel[:work_order_items][:id] => id)
        .select(Sequel[:work_order_items][:id], :template_name, :work_order_id, :product_setup_id, Sequel.function(:fn_product_setup_code, :product_setup_id).as(:product_setup_code), Sequel[:work_order_items][:carton_qty_required],
                Sequel[:work_order_items][:carton_qty_produced], Sequel[:work_order_items][:completed], Sequel[:work_order_items][:completed_at],
                Sequel.function(:fn_current_status, 'work_order_items', Sequel[:work_order_items][:id]).as(:status)).first
    end

    def find_work_order_items_by_templates(ids)
      DB[:work_order_items]
        .join(:product_setups, id: :product_setup_id)
        .join(:product_setup_templates, id: :product_setup_template_id)
        .where(Sequel[:product_setup_templates][:id] => ids)
        .select(Sequel[:work_order_items][:id], :template_name).all
    end
  end
end
