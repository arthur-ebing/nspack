# frozen_string_literal: true

require 'socket'
module MesscadaApp
  module Job
    class ClearMesScadaRobotLogins < BaseQueJob
      def run(system_resource_code, ip_address)
        sock = TCPSocket.open(ip_address, 2172)
        request = 'ClearLogins'
        puts "CLEAR MESSCADA LOGINS AT #{system_resource_code} (#{ip_address})"

        sock.puts request
        result = sock.read

        puts "RESPONSE FROM #{system_resource_code} : #{result}"
        sock.close
        finish
      end
    end
  end
end
