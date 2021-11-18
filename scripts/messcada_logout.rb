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
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb MesScadaLogout
# Live  : RACK_ENV=production ruby scripts/base_script.rb MesScadaLogout
# Dev   : ruby scripts/base_script.rb MesScadaLogout
#
class MesScadaLogout < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    rec = case args[0]
          when 'hans'
            DB[:contract_workers].where(surname: 'Zietsman').first
          when 'rupert'
            DB[:contract_workers].where(surname: 'Swanepoel', first_name: 'Rupert').first
          else
            err = "UNKNOWN arg: '#{args[0]}'"
            puts err
            return failed_response(err)
          end
    sys_id = DB[:system_resources].where(system_resource_code: 'LBL-3A').get(:id)
    raise 'No system resource found with code LBL-3A' if sys_id.nil?

    DB.transaction do
      DB[:system_resource_logins].where(contract_worker_id: rec[:id], active: true).update(last_logout_at: Time.now, from_external_system: false, active: false)
      Que.enqueue sys_id, 'LBL-3A', '192.168.50.215', rec[:id], job_class: 'MesscadaApp::Job::LogoutFromMesScadaRobot', queue: 'nspack'
    end

    if debug_mode
      success_response('Dry run complete')
    else
      success_response("MesScada robot logout performed for #{rec[:first_name]} #{rec[:surname]}...")
    end
  end
end
