# frozen_string_literal: true

module FinishedGoods
  module Dispatch
    module Load
      class TitanAddendum
        def self.call(load_id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:titan_addendum, :new, load_id: load_id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: "/finished_goods/dispatch/loads/#{load_id}",
                                  style: :back_button)
            end
            page.form do |form|
              form.caption 'Titan Addendum'
              form.no_submit!
              form.row do |row|
                row.column do |col|
                  col.add_field :load_id
                  col.add_field :request_type
                  col.add_field :success
                end
                row.blank_column
              end
            end
            page.section do |section|
              section.show_border!
              ui_rule.form_object.progress_controls.each do |control|
                section.add_control(control)
              end
            end
            page.section do |section|
              section.add_grid('titan_requests',
                               "/list/titan_requests/grid?key=addendum&load_id=#{load_id}",
                               caption: 'Requests')
            end
          end

          layout
        end
      end
    end
  end
end
