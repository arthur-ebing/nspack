# frozen_string_literal: true

module Production
  module Orders
    module WorkOrder
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:work_order, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.form do |form|
                # form.caption 'Work Order'
                form.view_only!
                form.add_field :marketing_order_id
                form.add_field :start_date
                form.add_field :end_date
                form.add_field :active
                form.add_field :completed
                form.add_field :completed_at
              end

              section.add_grid('work_order_items',
                               "/list/view_work_order_items_list/grid?key=standard&work_order_id=#{id}",
                               caption: 'Work Orders')
            end
          end

          layout
        end
      end
    end
  end
end
