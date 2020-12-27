# frozen_string_literal: true

module ProductionApp
  module Job
    class PingRobots < BaseQueJob
      attr_reader :repo, :user_name

      self.maximum_retry_count = 0

      def run(user_name) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        robots = ProductionApp::DashboardRepo.new.robot_system_resources_for_ping
        threads = []
        robots.each do |robot| # rubocop:disable Metrics/BlockLength
          id = robot[:id]
          ip = robot[:ip_address]
          call_robot = robot[:equipment_type] != 'robot-rpi'
          json_robot = robot[:module_function] == 'TERMINAL' # ...OR...
          mac_addr = robot[:mac_address]
          threads << Thread.new do
            ht = Crossbeams::HTTPCalls.new
            colour = if ht.can_ping?(ip)
                       'bg-green'
                     else
                       call_robot = false
                       'bg-red'
                     end
            work = [{ toggle_classes: { id: "ping-#{id}", rem_classes: ['bg-yellow'], add_classes: [colour] } }]
            work << { toggle_classes: { id: "run-#{id}", rem_classes: ['bg-yellow'], add_classes: [colour] } } unless call_robot
            send_bus_message_to_page(work, 'robot_states')
          rescue StandardError => e # # rubocop:disable Layout/RescueEnsureAlignment
            send_bus_message("Err for ping #{ip}: #{e.message} #{e.backtrace[0]}", message_type: :error, target_user: user_name)
          end

          # next unless call_robot

          threads << Thread.new do
            ht = Crossbeams::HTTPCalls.new
            # if json robot...
            # call ip:80/control.cgi
            # - with { requestInformation: { MAC: '...' } }
            # curl -d '{"requestInformation":{"MAC":"00:60:35:29:A8:A9"}}' -H 'Content-Type: application/json' http://172.16.147.2:80/control.cgi
            # {"status":"OK","deviceInfo":{"model":"ROBOT-T201","macaddress":"00:60:35:29:A8:A9","serialno":"1000000","mandate":"17-09-2020","firmware":"2.4.JSON2.0.HTTP","hwrev":"1B","etherports":"1","serial232ports":"2","serial485ports":"0","usbslaveports":"1","uptime":"325820"}}
            # returns...
            res = if json_robot
                    ht.json_post("http://#{ip}:80/control.cgi", requestInformation: { MAC: mac_addr })
                  else
                    ht.request_get("http://#{ip}:2080/?Type=SoftwareRevision")
                  end
            work = if res.success
                     ver = if json_robot
                             resp = JSON.parse(res.instance.body)
                             p resp
                             resp['deviceInfo']['firmware']
                           else
                             res.instance.body.split('Version="').last.split('"').first
                           end
                     [{ toggle_classes: { id: "run-#{id}", rem_classes: ['bg-yellow'], add_classes: ['bg-green'] } },
                      { set_inner_value: { id: "ver-#{id}", val: ver } }]
                   else
                     [{ toggle_classes: { id: "run-#{id}", rem_classes: ['bg-yellow'], add_classes: ['bg-red'] } }]
                   end
            send_bus_message_to_page(work, 'robot_states')
          rescue StandardError => e # # rubocop:disable Layout/RescueEnsureAlignment
            send_bus_message("Err for ver #{ip}: #{e.message}", message_type: :error, target_user: user_name)
          end
        end

        # threads.each { |thr| thr.abort_on_exception = true }
        threads.each(&:join)
        finish
      end
    end
  end
end
