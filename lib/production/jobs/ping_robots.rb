# frozen_string_literal: true

module ProductionApp
  module Job
    class PingRobots < BaseQueJob
      attr_reader :repo, :user_name

      self.maximum_retry_count = 0

      def run(params) # rubocop:disable Metrics/AbcSize
        threads = []
        threads << Thread.new do
          ht = Crossbeams::HTTPCalls.new
          if ht.can_ping?(params[:ip])
            work = { toggle_classes: { id: 'ping-560', rem_classes: ['bg-orange'], add_classes: ['bg-green'] } }
            send_bus_message_to_page([work], 'robot_states', message: 'IP could be reached', message_type: :success)
          else
            send_bus_message('IP could NOT be reached', message_type: :failure)
          end
        end

        threads << Thread.new do
          ht = Crossbeams::HTTPCalls.new
          res = ht.request_get("http://#{params[:ip]}:2080/?Type=SoftwareRevision")
          if res.success
            ver = res.instance.body.split('Version="').last.split('"').first
            # replace inner html & change orange to green
            # send_bus_message(ver, message_type: :success)
            work = [{ toggle_classes: { id: 'run-560', rem_classes: ['bg-orange'], add_classes: ['bg-green'] } },
                    { set_inner_value: { id: 'ver-560', val: ver } }]
            send_bus_message_to_page(work, 'robot_states')
          else
            send_bus_message(res.message, message_type: :failure)
          end
        end

        threads.each(&:join)
        finish
      end
    end
  end
end
