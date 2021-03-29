# frozen_string_literal: true

module Production
  module Orders
    module WorkOrder
      class Confirm
        def self.call(id, deselected_setup_templates)
          ui_rule = UiRules::Compiler.new(:work_order, :confirm, id: id, deselected_setup_templates: deselected_setup_templates)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.add_text rules[:confirm_message]
            page.form do |form|
              form.caption 'Confirm'
              form.action "/production/orders/work_orders/#{id}/create_work_order_items_submit"
              form.remote!
              form.add_text 'Do you want to continue?'
              # form.add_notice notice, show_caption: false
              form.submit_captions('Yes, continue')
            end
          end

          layout
        end
      end
    end
  end
end
