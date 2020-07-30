# frozen_string_literal: true

module Production
  module Dashboards
    module Dashboard
      class LoadDays
        def self.call
          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.add_text 'Loads per day', wrapper: :h2
            page.add_text draw_boxes
          end

          layout
        end

        def self.draw_boxes
          recs = ProductionApp::DashboardRepo.new.loads_per_day
          return 'There are no loads to display' if recs.empty?

          <<~HTML
            <div class="flex flex-column">
              #{loads(recs).join("\n")}
            </div>
          HTML
        end

        def self.loads(groups)
          shipped_lkp = ProductionApp::DashboardRepo.new.shipped_loads_per_day
          cnt = 0
          groups.map do |day, recs|
            cnt += 1
            next if cnt > 2

            loads_shipped = shipped_lkp[day] || 0
            <<~HTML
              <div class="flex flex-column mv2 bg-mid-gray pt1 pl2 pb2 outline">
                <div class="flex flex-wrap near-white">
                  <div class="pa2 mr2 mt2 fw8"> #{day.strftime('%A, %d %b %Y')}</div>
                </div>

                <div class="flex flex-wrap">
                  #{total_day(loads_shipped, recs)}
                  #{day_items(recs).join("\n")}
                </div>
              </div>
            HTML
          end
        end

        def self.total_day(loads_shipped, recs)
          pallets_shipped = 0
          recs.each do |rec|
            pallets_shipped += rec[:shipped]
          end
          <<~HTML
            <div class="outline pa2 mr2 mt2" style="background:#e6f4f1">
              <p class="bt bb fw7 mb4">Shipped Loads</p>
              <table>
                <tr><td class="pa1">Loads:</td><td class="fw7 f4 tr">#{loads_shipped}</td></tr>
                <tr><td class="pa1">Pallets:</td><td class="fw7 f4 tr">#{pallets_shipped}</td></tr>
              </table>
            </div>
          HTML
        end

        def self.day_items(recs)
          recs.map do |rec|
            <<~HTML
              <div class="outline pa2 mr2 mt2 bg-washed-blue">
                <p class="bt bb fw7">Loads: #{rec[:no_loads]}</p>
                <table>
                  <tr><td class="pa1">POL:</td><td>#{rec[:pol]}</td></tr>
                  <tr><td class="pa1">POD:</td><td>#{rec[:pod]}</td></tr>
                  <tr><td class="pa1">TM:</td><td>#{rec[:packed_tm_group]}</td></tr>
                </table>
                <table class="mt1" style="background-color:#8ABDEA;width:100%">
                  <tr><td class="pa1">Allocated:</td><td class="tr">#{rec[:allocated]}</td></tr>
                  <tr><td class="pa1">Shipped:</td><td class="tr">#{rec[:shipped]}</td></tr>
                </table>
              </div>
            HTML
          end
        end
      end
    end
  end
end
