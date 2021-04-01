# frozen_string_literal: true

# What this script does:
# ----------------------
# Restores the audit tables for backups done without audit tables
#
# Reason for this script:
# -----------------------
# Need's to be done
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb RestoreNoAuditBackupTables
# Live  : RACK_ENV=production ruby scripts/base_script.rb RestoreNoAuditBackupTables
# Dev   : ruby scripts/base_script.rb RestoreNoAuditBackupTables
#
class RestoreNoAuditBackupTables < BaseScript
  def run
    script = File.read(File.join(@root_dir, 'scripts', 'restore_no_audit_backup_tables.sql'))
    if debug_mode
      puts script
    else
      DB.transaction do
        DB.run(script)
      end
    end

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Applied the DB change')
    end
  end
end
