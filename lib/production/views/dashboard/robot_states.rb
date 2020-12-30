# frozen_string_literal: true

module Production
  module Dashboards
    module Dashboard
      class RobotStates
        def self.call
          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.add_text 'Robot states', wrapper: :h2
            page.add_text draw_states
            page.add_repeating_request '/production/dashboards/run_robot_state_checks', 1000, ''
          end

          layout
        end

        def self.draw_states
          recs = ProductionApp::DashboardRepo.new.robot_states # should be per line, type...
          return 'There are no robot resources to display' if recs.empty?

          <<~HTML
            <div class="flex flex-column">
              <div class="flex flex-column mv2 bg-mid-gray pt1 pl2 pb2 outline">
                <div class="flex flex-wrap near-white">
                  <div class="pa2 mr2 mt2 fw8"> All Robots</div>
                </div>

                <div class="flex flex-wrap">
                  #{robots(recs).join("\n")}
                </div>
              </div>
            </div>
          HTML
        end

        def self.robots(recs)
          # <div class="tc pa2" style="background: linear-gradient(90deg, #8ABDEA #{rec[:percentage].to_i}%, #e6f4f1 #{rec[:percentage].to_i}%);">
          #   <span class="fw6 f2 mid-gray ">#{rec[:percentage].to_i}%</span><br>
          # <table style="width:100%"><tr><td>#{rec[:pallet_qty] || 0} cartons</td><td>#{rec[:cartons_per_pallet] || 0} cpp</td></tr></table></div>
          # .led_light {
          #   height: 2em;
          #   width: 2em;
          #   margin: 1em;
          #   border-radius: 50%;
          # }
          # #led_red {
          #   background-color: red;
          # }
          recs.map do |rec|
            <<~HTML
              <div class="outline pa2 mr3 mt2 bg-white" style="min-width:230px">
                <p class="fw6 f4 mt0 pb1 bb">#{rec[:plant_resource_code]}</p>
                <p class="fw7 tc">#{rec[:system_resource_code]}</p>
                <p><table class="thinbordertable" style="width:100%">
                <tr><td>Ping:</td>
                <td><div id="ping-#{rec[:system_resource_id]}" class="bg-yellow br4 ba h1 w1"></div></td>
                <td>Running:</td>
                <td><div id="run-#{rec[:system_resource_id]}" class="bg-yellow br4 ba h1 w1"></div></td></tr>
                <tr><th colspan="2">Version</th><td colspan="2" id="ver-#{rec[:system_resource_id]}"></td></tr>
                </table></p>
                <p><table class="thinbordertable" style="width:100%">
                <tr><th class="tl">IP:</th><td>#{rec[:ip_address]}&nbsp;</td></tr>
                <tr><th class="tl">MAC:</th><td>#{rec[:mac_address]}&nbsp;</td></tr>
                <tr><th class="tl">Type:</th><td>#{rec[:equipment_type]}&nbsp;</td></tr>
                </table></p>
                <p>#{rec[:robot_function]}</p>
              </div>
            HTML
          end
        end
      end
    end
  end
end
