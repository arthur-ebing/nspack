# frozen_string_literal: true

module MesscadaApp
  class RefreshMesScadaGroupDisplay < BaseService
    attr_reader :repo, :system_resource_id

    def initialize(system_resource_id)
      @system_resource_id = system_resource_id
      @repo = MesscadaApp::MesscadaRepo.new
    end

    def call
      opts = DB[:system_resources].where(id: system_resource_id).select(:system_resource_code, :ip_address, :legacy_messcada).first
      return ok_Response unless opts[:legacy_messcada]

      new_group = legacy_group_name(opts)
      make_tcp_call(opts, new_group)

      ok_response
    end

    private

    def legacy_group_name(opts)
      DB[Sequel[:kromco_legacy][:messcada_group_data]].where(module_name: opts[:system_resource_code]).get(:group_id)
    end

    def make_tcp_call(opts, new_group)
      request = %(<RefreshGroupDisplay PID="436" Group="#{new_group}" />)

      sock = TCPSocket.open(opts[:ip_address], 2071)
      puts "MESSCADA REFRESH GROUP AT #{opts[:system_resource_code]} (#{opts[:ip_address]}) : #{new_group}"
      puts "MESSCADA PAYLOAD #{request}"

      sock.puts request
      result = sock.read

      puts "RESPONSE FROM #{opts[:system_resource_code]} : #{result}"
      sock.close
    end
  end
end
