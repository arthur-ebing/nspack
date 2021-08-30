# frozen_string_literal: true

module Production
  module Dashboards
    module Dashboard
      class GossamerDataDetail
        def self.call
          Crossbeams::Layout::Page.build({}) do |page|
            page.add_text draw_boxes
          end
        end

        def self.draw_boxes
          recs = ProductionApp::DashboardRepo.new.gossamer_data
          return('There is no Gossamer data to display') if recs.empty?

          <<~HTML
            <div class="flex flex-wrap pa3 bg-mid-gray">
              #{gossamer_items(recs).join("\n")}
            </div>
          HTML
        end

        def self.gossamer_items(recs)
          inflector = Dry::Inflector.new
          recs.map do |rec|
            <<~HTML
              <div class="outline pa2 mr3 mt2 bg-white" style="min-width:230px">
                <p class="fw6 f4 mt0 pb1 bb">#{rec['Alias']}: #{rec['Name']} - #{rec['Side']} (#{rec['Model']} #{rec['NetworkInterface']})</p>
                <div class="fw6 pa2 mid-gray flex flex-wrap">
                  #{details(rec, inflector)}
                </div>
              </div>
            HTML
          end
        end

        def self.details(rec, inflector)
          %w[MachineID PackCount LabelPrintQty PrintCommand Accumulator-70% Accumulator%
             Alarm-Active Alarm-Code TotalCount Producing NoProduct NoCartons BuildBack
             Stopped Fault Total-Spare-1 Total-Spare-2 Total-Spare-3 ActiveCounter SpeedPerHour].map do |key|
               <<~HTML
                 <div class="ml2 mb3 ba w5">
                   <div class="pa3" style="background-color:#e6f4f1">#{inflector.humanize(inflector.underscore(key))}</div>
                   <div class="f2 tr pa2">#{UtilityFunctions.delimited_number(rec[key], no_decimals: 0, delimiter: ' ')}</div>
                 </div>
               HTML
             end.join
        end
      end
    end
  end
end
