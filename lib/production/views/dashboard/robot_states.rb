# frozen_string_literal: true

module Production
  module Dashboards
    module Dashboard
      class RobotStates
        def self.call
          Crossbeams::Layout::Page.build({}) do |page|
            page.add_text 'Robot states', wrapper: :h2
            page.add_text draw_states
            page.add_repeating_request '/production/dashboards/run_robot_state_checks', 2000, ''
          end
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
          recs.map do |rec|
            <<~HTML
              <div class="outline pa2 mr3 mt2 bg-white" style="min-width:230px">
                <p class="fw6 f4 mt0 pb1 bb">#{rec[:plant_resource_code]}</p>
                <p>#{rec[:plant_description]}</p>
                <p class="fw7 tc pv3 mb0" style="background-color:#8ABDEA">#{rec[:system_resource_code]}</p>
                <div class="flex justify-around bg-light-yellow pv2">
                  <div id="ping-#{rec[:system_resource_id]}" class="light-yellow flex justify-center items-center br-100 h4 w4 tc">Network</div>
                  <div id="run-#{rec[:system_resource_id]}" class="ml2 light-yellow flex justify-center items-center br-100 h4 w4 tc">Software</div>
                </div>
                <p>Software version: <span id="ver-#{rec[:system_resource_id]}">&nbsp;</span></p>
                <p><table class="thinbordertable" style="width:100%;background-color:#e6f4f1">
                <tr><th class="tl">IP:</th><td>#{rec[:ip_address]}&nbsp;</td></tr>
                <tr><th class="tl">MAC:</th><td>#{rec[:mac_address]}&nbsp;</td></tr>
                <tr><th class="tl">Type:</th><td>#{rec[:equipment_type]}&nbsp;</td></tr>
                </table></p>
                <p>#{rec[:robot_function]}</p>
                #{buttons(rec[:id])}
                #{indiv(rec[:login], rec[:group_incentive], rec[:system_resource_id])}
                #{group(rec[:group_incentive], rec[:system_resource_id])}
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
            <details class="pv2">
              <summary class="pointer b blue shadow-3 pa1 mr2">Button allocations</summary>
              <table class="thinbordertable f6 mt3" style="width:100%">
              <tr><th>Button</th><th>Setup</th><th>Label</th></tr>
              #{items.join}
              </table>
            </details>
          HTML
        end

        def self.indiv(login, group_incentive, system_resource_id) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
          return '' if group_incentive
          return '' unless login

          list = ProductionApp::DashboardRepo.new.robot_logon_details(system_resource_id)
          if list.empty?
            '<div class="bg-purple white pa3 tc">Individual Incentive</div>'
          else
            items = list.map do |item|
              worker = [item[:first_name], item[:surname], "(#{item[:personnel_number]})"].compact.join(' ')
              if item[:active]
                <<~HTML
                  <tr class="bg-green white"><td><span class="b">#{worker}</span></td></tr>
                  <tr class="bg-green white"><td>Login on reader: <span class="b">#{item[:card_reader]}</span></td>
                  <tr class="bg-green white"><td>at <span class="b">#{item[:login_at].strftime('%H:%M:%S')}</span> on <span class="b">#{item[:login_at].strftime('%Y-%m-%d')}</span></td>
                HTML
              else
                <<~HTML
                  <tr class="bg-orange white"><td><span class="b">#{worker}</span></td></tr>
                  <tr class="bg-orange white"><td>Logout on reader: <span class="b">#{item[:card_reader]}</span></td>
                  <tr class="bg-orange white"><td>at <span class="b">#{item[:last_logout_at].nil? ? '' : item[:last_logout_at].strftime('%H:%M:%S')}</span> on <span class="b">#{item[:last_logout_at].nil? ? '' : item[:last_logout_at].strftime('%Y-%m-%d')}</span></td>
                HTML
              end
            end
            <<~HTML
              <div class="bg-purple white pa3 tc">Individual Incentive</div>
              <table class="thinbordertable f6 mt3" style="width:100%">
              #{items.join}
              </table>
            HTML
          end
        end

        def self.group(group_incentive, system_resource_id)
          return '' unless group_incentive

          list = ProductionApp::DashboardRepo.new.robot_group_incentive_details(system_resource_id)
          if list.empty?
            '<div class="bg-dark-blue white pa3 tc">Group Incentive</div>'
          else
            items = list.map do |item|
              %(<tr><td>#{item[:first_name]}</td><td>#{item[:surname]}</td><td>#{item[:personnel_number]}</td></tr>)
            end
            <<~HTML
              <div class="bg-dark-blue white pa3 tc">Group Incentive</div>
              <details class="pv2">
                <summary class="pointer b blue shadow-3 pa1 mr2">Active group members</summary>
                <table class="thinbordertable f6 mt3" style="width:100%">
                <tr><th>First name</th><th>Surname</th><th>Personnel no.</th></tr>
                #{items.join}
                </table>
              </details>
            HTML
          end
        end
      end
    end
  end
end
