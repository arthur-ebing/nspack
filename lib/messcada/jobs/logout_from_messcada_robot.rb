# frozen_string_literal: true

require 'socket'
module MesscadaApp
  module Job
    # Job to logout from a MesScada robot so that it can refresh its GUI.
    class LogoutFromMesScadaRobot < BaseQueJob
      self.maximum_retry_count = 0

      def run(system_resource_id, system_resource_code, ip_address, contract_worker_id) # rubocop:disable Metrics/AbcSize
        opts = DB[:system_resources].where(id: system_resource_id).select(:login, :group_incentive, :legacy_messcada).first
        return unless opts[:legacy_messcada]

        reader_id = DB[:system_resource_logins].where(system_resource_id: system_resource_id, active: false).order(:last_logout_at).reverse.get(:card_reader)

        worker = DB[:contract_workers].join(:personnel_identifiers, id: :personnel_identifier_id).where(Sequel[:contract_workers][:id] => contract_worker_id).select(:first_name, :surname, :personnel_number, :identifier).first
        new_group = DB[Sequel[:kromco_legacy][:messcada_group_data]].where(module_name: system_resource_code).get(:group_id) if opts[:group_incentive]

        request = %(<LogoffMes PID="430" Type="local" ReaderID="#{reader_id || '1'}" Name="#{worker[:first_name]} #{worker[:surname]}" RFID="#{worker[:identifier]}" IndustryNumber="#{worker[:personnel_number]}" Group="#{new_group}" />)
        # <LogoffMes PID="430"  Module="LBL-3A"  Type="local" ReaderID="1" Name="Sannie Smith"  RFID="9876512345"  IndustryNumber="12345" />
        AppConst.log_authentication("TCP logoff messcada - #{request}")

        sock = TCPSocket.open(ip_address, 2071)
        puts "MESSCADA LOGOUT AT #{system_resource_code} (#{ip_address}) : #{worker[:first_name]} #{worker[:surname]} (#{worker[:personnel_number]})"
        puts "MESSCADA PAYLOAD #{request}"

        sock.puts request
        result = sock.read

        puts "RESPONSE FROM #{system_resource_code} : #{result}"
        AppConst.log_authentication("TCP logoff messcada result - #{result}")
        sock.close
        finish
      end
    end
  end
end
