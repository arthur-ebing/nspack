# frozen_string_literal: true

module Production
  module Shifts
    module Shift
      class Edit
        def self.call(id, form_values: nil, form_errors: nil, current_user: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:shift, :edit, id: id, form_values: form_values, current_user: current_user)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors

            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back to Shifts',
                                  url: '/list/shifts',
                                  style: :back_button)
            end
            page.section do |section|
              section.form do |form|
                form.caption 'Edit Shift'
                form.action "/production/shifts/shifts/#{id}"
                form.remote!
                form.method :update
                form.row do |row|
                  row.column do |col|
                    col.add_field :shift_type_id
                    col.add_field :shift_type_code
                    col.add_field :running_hours
                  end
                  row.column do |col|
                    col.add_field :start_date_time
                    col.add_field :end_date_time
                  end
                end
              end
            end

            page.section do |section|
              section.show_border!
              # unless cannot_edit
              # new_item_url = rules[:on_consignment] ? "/pack_material/replenish/mr_deliveries/#{id}/mr_delivery_items/new_item_on_consignment" : "/pack_material/replenish/mr_deliveries/#{id}/mr_delivery_items/preselect"
              section.add_control(control_type: :link,
                                  text: 'New Item',
                                  url: "/production/shifts/shifts/#{id}/shift_exceptions/preselect",
                                  style: :button,
                                  behaviour: :popup,
                                  grid_id: 'exceptions',
                                  css_class: 'mb1')
              section.add_grid('exceptions',
                               "/list/shift_exceptions/grid?key=standard&shift_id=#{id}",
                               height: 16,
                               caption: 'Shift Exceptions')
              # end
              # if (rules[:can_add_invoice] || rules[:can_complete_invoice]) && !rules[:invoice_completed] || rules[:over_supply_accepted]
              #   section.add_grid('del_items',
              #                    "/list/mr_delivery_items_edit_unit_prices/grid?key=standard&delivery_id=#{id}",
              #                    height: 16,
              #                    caption: 'Delivery Line Items')
              # end
              # if rules[:invoice_completed]
              #   section.add_grid('del_items',
              #                    "/list/mr_delivery_items_show/grid?key=standard&delivery_id=#{id}",
              #                    height: 16,
              #                    caption: 'Delivery Line Items')
              # end
            end
          end

          layout
        end
      end
    end
  end
end
