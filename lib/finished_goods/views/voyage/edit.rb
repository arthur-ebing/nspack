# frozen_string_literal: true

module FinishedGoods
  module Dispatch
    module Voyage
      class Edit
        def self.call(id, back_url: nil, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:voyage, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: back_url,
                                  style: :back_button)
            end

            page.form do |form|
              form.action "/finished_goods/dispatch/voyages/#{id}"
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :voyage_type_id
                  col.add_field :vessel_id
                  col.add_field :voyage_number
                end
                row.column do |col|
                  col.add_field :voyage_code
                  col.add_field :year
                  col.add_field :completed
                  col.add_field :completed_at
                end
              end
            end
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Complete Voyage',
                                  url: "/finished_goods/dispatch/voyages/#{id}/complete",
                                  behaviour: :popup,
                                  visible: rules[:can_complete],
                                  style: :button)
              section.add_control(control_type: :link,
                                  text: 'Add Port',
                                  url: "/finished_goods/dispatch/voyages/#{id}/voyage_ports/new",
                                  behaviour: :popup,
                                  grid_id: 'voyage_ports',
                                  visible: !rules[:completed],
                                  style: :button)
              section.add_grid('voyage_ports',
                               "/list/voyage_ports/grid?key=standard&voyage_id=#{id}",
                               caption: 'Voyage Ports',
                               height: 10)
              section.add_grid('loads',
                               "/list/loads/grid?key=standard&voyage_id=#{id}",
                               height: 40,
                               caption: 'Loads')
            end
          end

          layout
        end
      end
    end
  end
end
