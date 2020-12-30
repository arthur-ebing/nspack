# frozen_string_literal: true

module Production
  module Dashboards
    module Dashboard
      class RobotStates
        def self.call
          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.add_text 'Robot states', wrapper: :h2
            page.add_text draw_states
            page.add_repeating_request '/production/dashboards/run_robot_state_checks', 2000, ''
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
                <p>#{rec[:plant_description]}</p>
                <p class="fw7 tc pv3" style="background-color:#8ABDEA">#{rec[:system_resource_code]}</p>
                <div class="flex justify-around">
                  <div id="ping-#{rec[:system_resource_id]}" class="white b pa2 ba br3">Network</div>
                  <div id="run-#{rec[:system_resource_id]}" class="white b pa2 ba br3">Software</div>
                </div>
                <p>Software version: <span id="ver-#{rec[:system_resource_id]}">&nbsp;</span></p>
                <p><table class="thinbordertable" style="width:100%;background-color:#e6f4f1">
                <tr><th class="tl">IP:</th><td>#{rec[:ip_address]}&nbsp;</td></tr>
                <tr><th class="tl">MAC:</th><td>#{rec[:mac_address]}&nbsp;</td></tr>
                <tr><th class="tl">Type:</th><td>#{rec[:equipment_type]}&nbsp;</td></tr>
                </table></p>
                <p>#{rec[:robot_function]}</p>
                #{buttons(rec[:id])}
              </div>
            HTML
          end
        end

        def self.buttons(plant_resource_id)
          list = ProductionApp::DashboardRepo.new.robot_button_states(plant_resource_id)
          return if list.empty?

          items = list.map do |btn, code, lbl|
            %(<tr><td>#{btn}</td><td>#{code}</td><td>#{lbl}</td></tr>)
          end
          <<~HTML
            <p><table class="thinbordertable f7" style="width:100%">
            <caption>Button allocations</caption>
            <tr><th>Button</th><th>Setup</th><th>Label</th></tr>
            #{items.join}
            </table></p>
          HTML
        end
      end
    end
  end
end
