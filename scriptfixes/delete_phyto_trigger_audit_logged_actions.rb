# frozen_string_literal: true

# What this script does:
# ----------------------
# For audit.logged_actions it deletes the update records that was created by the faulty trigger.
#
# DELETE FROM audit.logged_actions
# WHERE table_name = 'pallet_sequences'
# AND akeys(changed_fields) = ARRAY['phyto_data']
# AND action_tstamp_tx < '2020-05-20 00:00'
#
# Reason for this script:
# -----------------------
# OTMC test require that the phyto data be cached on the pallet_sequences table, the trigger that cached the data updated the entire table instead of only the affected record.
#
# As a result the audit tables logged unnecessary changes bloating the data base to almost 4 times its size
#
# This script is to remove the audit record in order to reduce the size of the data base
#
class DeletePhytoTriggerAuditLoggedActions < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    query = <<~SQL
      SELECT
          event_id
      FROM audit.logged_actions
      WHERE table_name = 'pallet_sequences'
      AND akeys(changed_fields) = ARRAY['phyto_data']
      AND action_tstamp_tx < '2020-05-20 00:00'
      ORDER BY event_id
    SQL
    event_ids = DB[query].select_map(:event_id)

    if debug_mode
      puts "Deleted records #{event_ids.count}"
    else
      DB.transaction do
        puts "Deleted records #{event_ids.count}"
        DB[Sequel[:audit][:logged_actions]].where(event_id: event_ids).delete
      end
    end

    infodump = <<~STR
      Script: DeletePhytoTriggerAuditLoggedActions

      What this script does:
      ----------------------
      For audit.logged_actions it deletes the update records that was created by the faulty trigger.
      DELETE FROM audit.logged_actions
      WHERE table_name = 'pallet_sequences'
      AND akeys(changed_fields) = ARRAY['phyto_data']
      AND action_tstamp_tx < '2020-05-20 00:00'

      Reason for this script:
      -----------------------
      OTMC test require that the phyto data be cached on the pallet_sequences table, the trigger that cached the data updated the entire table instead of only the affected record.

      As a result the audit tables logged unnecessary changes bloating the data base to almost 4 times its size
      This script is to remove the audit record in order to reduce the size of the data base

      Results:
      --------
      Updated something

      data: #{event_ids.join(', ')}
    STR

    log_infodump(:data_fix,
                 :phyto_trigger,
                 'Delete audit.logged_actions for incorrect phyto_trigger',
                 "Delete audit.logged_actions for incorrect phyto_trigger. #{infodump}")

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Something was done')
    end
  end
end
