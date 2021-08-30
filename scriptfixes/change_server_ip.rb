# frozen_string_literal: true

# What this script does:
# ----------------------
# Changes the ip address of the server in various configurations.
#
# Reason for this script:
# -----------------------
# If a live site changes its server ip address, there are configurations that need to be changed to use the new ip address.
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb ChangeServerIp from_ip to_ip
# Live  : RACK_ENV=production ruby scripts/base_script.rb ChangeServerIp from_ip to_ip
# Dev   : ruby scripts/base_script.rb ChangeServerIp from_ip to_ip
#
class ChangeServerIp < BaseScript
  attr_reader :from_ip, :to_ip

  def run # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    @from_ip = args.first
    @to_ip = args[1]
    raise ArgumentError, "<#{from_ip}> is not a valid ip address" unless valid_ip?(from_ip)
    raise ArgumentError, "<#{to_ip}> is not a valid ip address" unless valid_ip?(to_ip)
    raise ArgumentError, 'From and to ip addresses cannot be the same' if from_ip == to_ip
    raise ArgumentError, 'From ip addresses does not match currently set ip address' unless url_base_ip?

    env_local = prepare_env_changes
    printers = DB[:printers].where(server_ip: from_ip).select_map(:printer_code)
    mod_servers = DB[:mes_modules].where(server_ip: from_ip).select_map(:module_code)
    mod_ip = DB[:mes_modules].where(ip_address: from_ip).select_map(:module_code)
    sys_res = DB[:system_resources].where(ip_address: from_ip).select_map(:system_resource_code)

    if debug_mode
      puts "\nPrinters to change:"
      puts printers.join("\n")
      puts "\nModules to change:"
      puts mod_servers.join("\n")
      puts "\nServer Module to change:"
      puts mod_ip.join("\n")
      puts "\nSystem Resources to change:"
      puts sys_res.join("\n")
      puts "\nNEW .env.local:"
      puts env_local
    else
      # 1. .env.local
      # 2. available_printers
      # 3. available_modules
      # 4. system_resources
      DB.transaction do
        DB[:printers].where(server_ip: from_ip).update(server_ip: to_ip)
        DB[:mes_modules].where(server_ip: from_ip).update(server_ip: to_ip)
        DB[:mes_modules].where(ip_address: from_ip).update(ip_address: to_ip)
        DB[:system_resources].where(ip_address: from_ip).update(ip_address: to_ip)

        File.open(env_file_name, 'w') { |f| f.puts env_local }
      end
    end

    infodump = <<~STR
      Script: ChangeServerIp

      What this script does:
      ----------------------
      Changes the ip address of the server in various configurations.

      Reason for this script:
      -----------------------
      If a live site changes its server ip address, there are configurations that need to be changed to use the new ip address.

      Results:
      --------
      Changed server IP from: #{from_ip} to: #{to_ip}

      Printers changed:
      #{printers.join("\n")}

      Modules changed:
      #{mod_servers.join("\n")}

      Server Module changed:
      #{mod_ip.join("\n")}

      System Resources changed:
      #{sys_res.join("\n")}

      NEW .env.local:
      #{env_local}
    STR

    log_infodump(:config_fix,
                 :ip_address,
                 :server_ip_changed,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('New Server IP was applied')
    end
  end

  private

  def env_file_name
    File.join(File.expand_path('..', __dir__), '.env.local')
  end

  def prepare_env_changes
    ar = File.readlines(env_file_name)
    ar.map do |a|
      case a
      when /^URL_BASE=/
        a.gsub(from_ip, to_ip)
      when /^URL_BASE_IP=/
        a.gsub(from_ip, to_ip)
      when /^LABEL_SERVER_URI=/
        a.gsub(from_ip, to_ip)
      when /^LABEL_PUBLISH_NOTIFY_URLS=/
        a.gsub(from_ip, to_ip)
      else
        a
      end
    end.join
  end

  def valid_ip?(ip_address)
    block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
    re = /\A#{block}\.#{block}\.#{block}\.#{block}\z/
    re =~ ip_address
  end

  def url_base_ip?
    ENV['URL_BASE_IP'] =~ /#{from_ip}(?::\d{0,4})?$/ # rubocop:disable Lint/Env
  end
end
