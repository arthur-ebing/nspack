# frozen_string_literal: true

module FinishedGoods
  module Tripsheet
    class RefreshTripsheetConfirm
      def self.call(id, url: nil, notice: nil, remote: true) # rubocop:disable Metrics/AbcSize
        ui_rule = UiRules::Compiler.new(:govt_inspection_sheet, :show, id: id)
        rules   = ui_rule.compile

        layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
          page.form_object ui_rule.form_object
          page.add_text rules[:compact_header]
          page.form do |form| # rubocop:disable Metrics/BlockLength
            form.action url
            form.no_submit!
            form.remote! if remote
            # form.add_text notice

            form.row do |row|
              row.column do |col|
                col.add_text notice
              end
            end

            form.row do |row|
              row.column do |col|
                col.add_control(control_type: :link,
                                text: 'Abondon_Refresh?',
                                url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/refresh_tripsheet_cancelled",
                                visible: rules[:inspected],
                                style: :button)
              end

              row.column do |col|
                col.add_text 'OR'
              end

              row.column do |col|
                col.add_control(control_type: :link,
                                text: 'Refresh_And_Complete_Offload?',
                                url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/refresh_tripsheet_confirmed",
                                visible: rules[:inspected],
                                style: :button)
              end
            end
          end
        end

        layout
      end
    end
  end
end
