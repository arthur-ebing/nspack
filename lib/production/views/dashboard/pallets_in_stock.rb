# frozen_string_literal: true

module Production
  module Dashboards
    module Dashboard
      class PalletsInStock
        def self.call
          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.add_text 'Pallets in stock', wrapper: :h2
            page.add_text draw_boxes
          end

          layout
        end

        def self.draw_boxes
          recs = ProductionApp::DashboardRepo.new.pallets_in_stock
          <<~HTML
            <div class="flex flex-wrap pa3 bg-mid-gray">
              #{stock_items(recs).join("\n")}
            </div>
          HTML
        end

        def self.stock_items(recs)
          recs.map do |rec|
            <<~HTML
              <div class="outline pa2 mr3 mt2 bg-white" style="min-width:230px">
                <p class="fw6 mt0 pb1 bb">TM <span class="f4">#{rec[:packed_tm_group]}</span></p>
                <table style="width:100%">
                <tr><td>Cultivar</td><td>#{rec[:cultivar_name]}</td></tr>
                <tr><td>Pack</td><td>#{rec[:standard_pack_code]}</td></tr>
                </table>
                <p class="fw7 f2 tc pt2 pb2 mt0 mb0" style="background-color:#8ABDEA">#{rec[:pallet_count]}</p>
              </div>
            HTML
          end
        end
      end
    end
  end
end
