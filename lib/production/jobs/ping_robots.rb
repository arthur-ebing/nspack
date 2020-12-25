# frozen_string_literal: true

module ProductionApp
  module Job
    class PingRobots < BaseQueJob
      attr_reader :repo, :user_name

      self.maximum_retry_count = 0

      def run # rubocop:disable Metrics/AbcSize
        robots = ProductionApp::DashboardRepo.new.robot_system_resources_for_ping
        threads = []
        robots.each do |robot| # rubocop:disable Metrics/BlockLength
          id = robot[:id]
          ip = robot[:ip_address]
          call_robot = robot[:equipment_type] != 'robot-rpi'
          threads << Thread.new do
            ht = Crossbeams::HTTPCalls.new
            colour = if ht.can_ping?(ip)
                       'bg-green'
                     else
                       'bg-red'
                     end
            work = [{ toggle_classes: { id: "ping-#{id}", rem_classes: ['bg-yellow'], add_classes: [colour] } }]
            work << { toggle_classes: { id: "run-#{id}", rem_classes: ['bg-yellow'], add_classes: [colour] } } unless call_robot
            send_bus_message_to_page(work, 'robot_states')
          end

          next unless call_robot

          threads << Thread.new do
            ht = Crossbeams::HTTPCalls.new
            res = ht.request_get("http://#{ip}:2080/?Type=SoftwareRevision")
            work = if res.success
                     ver = res.instance.body.split('Version="').last.split('"').first
                     [{ toggle_classes: { id: "run-#{id}", rem_classes: ['bg-yellow'], add_classes: ['bg-green'] } },
                      { set_inner_value: { id: "ver-#{id}", val: ver } }]
                   else
                     [{ toggle_classes: { id: "run-#{id}", rem_classes: ['bg-yellow'], add_classes: ['bg-red'] } }]
                   end
            send_bus_message_to_page(work, 'robot_states')
          end
        end

        threads.each(&:join)
        finish
      end
    end
  end
end
