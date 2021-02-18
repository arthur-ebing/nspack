# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
module FinishedGoods
  module Inspection
    module GovtInspectionSheet
      class TitanInspection
        def self.call(govt_inspection_sheet_id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:titan_inspection, :inspection, govt_inspection_sheet_id: govt_inspection_sheet_id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: "/finished_goods/inspection/govt_inspection_sheets/#{govt_inspection_sheet_id}",
                                  style: :back_button)
            end
            page.form do |form|
              form.caption 'Titan Inspection'
              form.no_submit!
              form.view_only!
              form.row do |row|
                row.column do |col|
                  col.add_field :govt_inspection_sheet_id
                  col.add_field :request_type
                  col.add_field :success
                end
                row.blank_column
              end
            end
            controls = ui_rule.form_object.progress_controls
            p controls
            if controls
              page.section do |section|
                section.show_border!
                controls.each do |control|
                  section.add_control(control)
                end
              end
            end
            page.section do |section|
              section.add_grid('titan_requests',
                               "/list/titan_requests/grid?key=inspection&govt_inspection_sheet_id=#{govt_inspection_sheet_id}",
                               caption: 'Requests')
            end
          end
          layout
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
