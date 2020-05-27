# frozen_string_literal: true

# require 'logger'
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

    p "Records affected: #{event_ids.count}"
    DB[Sequel[:audit][:logged_actions]].where(event_id: event_ids).delete unless debug_mode
    p "Records deleted: #{event_ids.count}"

    log_infodump(:data_fix,
                 :phyto_trigger,
                 'Delete audit.logged_actions for incorrect phyto_trigger ',
                 "Delete audit.logged_actions for incorrect phyto_trigger, event_id:#{event_ids}")

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Data Updated')
    end
  end
end
