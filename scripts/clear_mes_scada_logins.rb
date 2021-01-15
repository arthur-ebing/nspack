# frozen_string_literal: true

# What this script does:
# ----------------------
# Takes all MesScada robots that are set to do group incentive or individual incentive and creates a job for each one that makes a TCP connection to clear logins on the GUI
#
# Reason for this script:
# -----------------------
# At the end of a shift a job logs all workers out in the database.
# For MesScada ITPCs, they also need to be told that the user has been logged out so that they can update their GUI.
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb ClearMesScadaLogins
# Live  : RACK_ENV=production ruby scripts/base_script.rb ClearMesScadaLogins
# Dev   : ruby scripts/base_script.rb ClearMesScadaLogins
#
class ClearMesScadaLogins < BaseScript
  def run
    puts 'RUNNING'
    robots = DB[:system_resources].where(legacy_messcada: true, login: true).select_map(%i[id system_resource_code ip_address])
    if debug_mode
      puts "MesScada Robots to clear:\n-------------------------\n#{robots.map { |_, c, i| "#{c} (#{i})" }.join("\n")}"
    else
      robots.each do |_, code, ip|
        Que.enqueue code, ip, job_class: 'MesscadaApp::Job::ClearMesScadaLogins', queue: AppConst::QUEUE_NAME
      end
    end

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('MesScada robots asked to clear logins')
    end
  end
end
