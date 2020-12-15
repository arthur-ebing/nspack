# frozen_string_literal: true

module Production
  module Dashboards
    module Dashboard
      class BinState
        def self.call
          repo = ProductionApp::DashboardRepo.new
          date1 = repo.last_bin_received_date
          date2 = date1.nil? ? nil : date1 - 1

          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.add_text 'Bin state', wrapper: :h2
            if date1.nil?
              page.add_text 'There are no bins to report on.'
            else
              page.add_text draw_boxes(repo, date1)
              page.add_text draw_boxes(repo, date2)
            end
          end

          layout
        end

        def self.draw_boxes(repo, date)
          tipped_recs = repo.tipped_bins_for_day(date)
          received_recs = repo.received_bins_for_day(date)
          load_recs = repo.loads_for_day(date)
          return "<h3>#{date.strftime('%A, %d %B %Y')}</h3> There is nothing to display" if tipped_recs.empty? && received_recs.empty? && load_recs.empty?

          <<~HTML
            <h3>#{date.strftime('%A, %d %B %Y')}</h3>
            <div class="flex flex-column">
              <div class="flex flex-column mv2 bg-mid-gray pt1 pl2 pb2 outline">
                #{bins('Tipped', tipped_recs)}
                #{bins('Received', received_recs)}
                <div class="flex flex-wrap near-white">
                  <div class="pa2 mr2 mt2 fw8"> Loads</div>
                </div>

                <div class="flex flex-wrap">
                #{loads(load_recs).join("\n")}
                </div>
              </div>
            </div>
          HTML
        end

        def self.bins(type, recs)
          <<~HTML
            <div class="flex flex-wrap near-white">
              <div class="pa2 mr2 mt2 fw8"> Bins #{type}</div>
            </div>

            <div class="flex flex-wrap">
              #{bin_items(recs).join("\n")}
            </div>
          HTML
        end

        def self.bin_items(recs)
          return ['<p class="near-white">No bins</p>'] if recs.empty?

          recs.map do |rec|
            <<~HTML
              <div class="outline pa2 mr2 mt2 bg-washed-blue">
                <p class="bt bb fw7">#{rec[:puc_code]}</p>
                <table>
                  <tr><td class="pa1">Orchard:</td><td>#{rec[:orchard_code]}</td></tr>
                  <tr><td class="pa1">Cultivar:</td><td>#{rec[:cultivar_name]}</td></tr>
                </table>
                <table class="mt1" style="background-color:#8ABDEA;width:100%">
                  <tr><td class="pa1">Bins:</td><td class="tr">#{rec[:qty_bins]}</td></tr>
                  <tr><td class="pa1">Weight:</td><td class="tr">#{UtilityFunctions.delimited_number(rec[:nett_weight])}</td></tr>
                </table>
              </div>
            HTML
          end
        end

        def self.loads(recs)
          return ['<p class="near-white">No loads</p>'] if recs.empty?

          recs.map do |rec|
            <<~HTML
              <div class="outline pa2 mr2 mt2 bg-washed-blue">
                <p class="bt bb fw7">Load: #{rec[:load_id]}</p>
                <table>
                  <tr><td class="pa1">Customer:</td><td>#{rec[:customer]}</td></tr>
                  <tr><td class="pa1">POL:</td><td>#{rec[:pol]}</td></tr>
                  <tr><td class="pa1">POD:</td><td>#{rec[:pod]}</td></tr>
                </table>
                <table class="mt1" style="background-color:#8ABDEA;width:100%">
                  <tr><td class="pa1">Pallets:</td><td class="tr">#{rec[:qty_pallets]}</td></tr>
                  <tr><td class="pa1">Weight:</td><td class="tr">#{UtilityFunctions.delimited_number(rec[:nett_weight])}</td></tr>
                </table>
              </div>
            HTML
          end
        end
      end
    end
  end
end
