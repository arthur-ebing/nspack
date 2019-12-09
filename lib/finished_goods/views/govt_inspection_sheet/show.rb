# frozen_string_literal: true

module FinishedGoods
  module Inspection
    module GovtInspectionSheet
      class Show
        def self.call(id)  # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:govt_inspection_sheet, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Print Passed Inspection Report',
                                  url: "/finished_goods/reports/passed_inspection_report/#{id}",
                                  visible: rules[:inspected],
                                  loading_window: true,
                                  style: :button)
              section.add_control(control_type: :link,
                                  text: 'Print Failed Inspection Report',
                                  url: "/finished_goods/reports/failed_inspection_report/#{id}",
                                  visible: rules[:inspected],
                                  loading_window: true,
                                  style: :button)
            end
            page.form do |form|
              form.caption 'Govt Inspection Sheet'
              form.action '/list/govt_inspection_sheets'
              form.submit_captions 'Close'
              form.row do |row|
                row.column do |col|
                  col.add_field :inspector_id
                  col.add_field :inspection_billing_party_role_id
                  col.add_field :exporter_party_role_id
                  col.add_field :booking_reference
                end
                row.column do |col|
                  col.add_field :inspection_point
                  col.add_field :destination_country_id
                  col.add_field :completed
                  col.add_field :inspected
                end
              end
            end
            page.section do |section|
              section.fit_height!
              section.add_grid('govt_inspection_pallets',
                               "/list/govt_inspection_pallets/grid?key=standard&id=#{id}",
                               caption: 'Govt Inspection Pallets')
            end
          end

          layout
        end
      end
    end
  end
end
