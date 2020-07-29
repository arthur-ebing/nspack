# frozen_string_literal: true

module Production
  module Dashboards
    module Dashboard
      class DeliveryDays
        def self.call
          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.add_text 'Deliveries per day', wrapper: :h2
            page.add_text draw_boxes
          end

          layout
        end

        def self.draw_boxes
          recs = ProductionApp::DashboardRepo.new.deliveries_per_day
          return 'There are no deliveries to display' if recs.empty?

          <<~HTML
            <div class="flex flex-column">
              #{deliveries(recs).join("\n")}
            </div>
          HTML
        end

        def self.deliveries(groups)
          cnt = 0
          groups.map do |day, recs|
            cnt += 1
            next if cnt > 2

            <<~HTML
              <div class="flex flex-column mv2 bg-mid-gray pt1 pl2 pb2 outline">
                <div class="flex flex-wrap near-white">
                  <div class="pa2 mr2 mt2 fw8"> #{day.strftime('%A, %d %b %Y')}</div>
                </div>

                <div class="flex flex-wrap">
                  #{day_items(recs).join("\n")}
                </div>
              </div>
            HTML
          end
        end

        def self.day_items(recs) # rubocop:disable Metrics/AbcSize
          recs.map do |rec|
            percentage = if rec[:qty_tipped].zero? || rec[:qty_bins].zero?
                           0
                         else
                           rec[:qty_tipped] / rec[:qty_bins].to_f * 100.0
                         end
            <<~HTML
              <div class="outline pa2 mr2 mt2 bg-washed-blue">
                <p class="bt bb fw7">Deliveries: #{rec[:no_deliveries]}</p>
                <table>
                  <tr><td class="pa1">Farm:</td><td>#{rec[:farm_code]}</td></tr>
                  <tr><td class="pa1">PUC:</td><td>#{rec[:puc_code]}</td></tr>
                  <tr><td class="pa1">Orchard:</td><td>#{rec[:orchard_code]}</td></tr>
                  <tr><td class="pa1">Cultivar:</td><td>#{rec[:cultivar_name]}</td></tr>
                </table>
                <div class="tc pa2 mb2" style="background: linear-gradient(90deg, #8ABDEA #{percentage.to_i}%, #e6f4f1 #{percentage.to_i}%);">
                  <span class="fw6 f2 mid-gray ">#{percentage.to_i}%</span><br>
                <table style="width:100%"><tr><td>#{rec[:qty_bins] || 0} bins</td><td>#{rec[:qty_tipped] || 0} tipped</td></tr></table></div>
              </div>
            HTML
          end
        end
      end
    end
  end
end
