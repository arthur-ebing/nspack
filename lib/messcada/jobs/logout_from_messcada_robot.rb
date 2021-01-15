# frozen_string_literal: true

require 'socket'
module MesscadaApp
  module Job
    # Job to logout from a MesScada robot so that it can refresh its GUI.
    class LogoutFromMesScadaRobot < BaseQueJob
      def run(system_resource_id, system_resource_code, ip_address, contract_worker_id) # rubocop:disable Metrics/AbcSize
        opts = DB[:system_resources].where(id: system_resource_id).select(:login, :group_incentive, :legacy_messcada).first
        return unless opts[:legacy_messcada]

        worker = DB[:contract_workers].where(id: contract_worker_id).select(:first_name, :surname, :industry_number).first
        request = if opts[:group_incentive]
                    new_group = DB[Sequel[:kromco_legacy][:messcada_group_data]].where(module_name: system_resource_code).get(:system_resource_code)
                    "Logout:group:#{new_group}worker:#{worker[:first_name]} #{worker[:surname]}:no:#{worker[:industry_number]}"
                  else
                    "Logout:worker:#{worker[:first_name]} #{worker[:surname]}:no:#{worker[:industry_number]}"
                  end
        sock = TCPSocket.open(ip_address, 2172)
        puts "MESSCADA LOGOUT AT #{system_resource_code} (#{ip_address}) : #{worker[:first_name]} #{worker[:surname]} (#{worker[:industry_number]})"

        sock.puts request
        result = sock.read

        puts "RESPONSE FROM #{system_resource_code} : #{result}"
        sock.close
        finish
      end
    end
  end
end
