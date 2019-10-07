# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
module FinishedGoods
  module Dispatch
    module Voyage
      class Edit
        def self.call(id, form_values: nil, form_errors: nil, back_url:) # rubocop:disable Metrics/AbcSize
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
              # form.caption 'Edit Voyage'
              form.action "/finished_goods/dispatch/voyages/#{id}"
              # form.remote!
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :voyage_type_id
                  col.add_field :vessel_id
                  col.add_field :voyage_number
                  col.add_field :voyage_code
                end
                row.column do |col|
                  col.add_field :year
                  col.add_field :completed
                  col.add_field :completed_at
                end
              end
            end
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Add Port',
                                  url: "/finished_goods/dispatch/voyages/#{id}/voyage_ports/new",
                                  behaviour: :popup,
                                  grid_id: 'voyage_ports',
                                  style: :button)

              section.add_grid('voyage_ports',
                               "/list/voyage_ports/grid?key=standard&voyage_id=#{id}",
                               caption: 'Voyage Ports')
            end
          end

          layout
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
