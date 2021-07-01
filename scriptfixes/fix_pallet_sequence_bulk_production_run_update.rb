# frozen_string_literal: true

# What this script does:
# ----------------------
#  1. loops through all reworks runs where the run type is BULK PRODUCTION RUN UPDATE.
#  2. for each rework, grab the list of affected pallets and before_state.
#  3. reverses update on sequences where production_run_id != from_production_run_id (reworks_run[:before_state].to_h[:production_run_id])
#  4. log status for each pallet sequences.
#
# Reason for this script:
# -----------------------
# BULK PRODUCTION RUN UPDATE RUN_TYPE - should only update sequences where production_run_id = from_production_run_id
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb FixPalletSequenceBulkProductionRunUpdate
# Live  : RACK_ENV=production ruby scripts/base_script.rb FixPalletSequenceBulkProductionRunUpdate
# Dev   : ruby scripts/base_script.rb FixPalletSequenceBulkProductionRunUpdate
#
class FixPalletSequenceBulkProductionRunUpdate < BaseScript
  def run # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    query = <<~SQL
      SELECT reworks_runs.id, pallets_affected
             ,COALESCE(reworks_runs.changes_made -> 'pallets' -> 'pallet_sequences' -> 'changes' -> 'before', null) AS before_state
      FROM reworks_runs
      JOIN reworks_run_types ON reworks_run_types.id = reworks_runs.reworks_run_type_id
      WHERE run_type = 'BULK PRODUCTION RUN UPDATE'
      ORDER BY id
    SQL
    reworks_runs = DB[query].all
    return failed_response("There are no #{AppConst::RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE} reworks_runs to fix") if reworks_runs.empty?

    reworks_run_ids = reworks_runs.map { |r| r[:id] }
    p "Reworks_runs records affected: #{reworks_run_ids.count}"

    text_data = []
    reworks_runs.each do |reworks_run|
      pallet_numbers = reworks_run[:pallets_affected][0]
      next if pallet_numbers.nil_or_empty?

      pallet_numbers = pallet_numbers.gsub(/['"]/, '').split("\n")
      pallet_numbers = pallet_numbers.map(&:strip).reject(&:empty?)
      pallet_sequence_ids = DB["SELECT DISTINCT id FROM pallet_sequences WHERE pallet_number IN ('#{pallet_numbers.join('\',\'')}') AND pallet_id IS NOT NULL"].map { |r| r[:id] } unless pallet_numbers.nil_or_empty?

      from_production_run_id = reworks_run[:before_state].to_h['production_run_id']
      pallet_sequence_ids.each do |pallet_sequence_id|
        before_state = get_audit_before_state(pallet_sequence_id)
        next if before_state.nil_or_empty?

        attrs = resolve_before_state_attrs(before_state)
        next if from_production_run_id.to_i == attrs[:production_run_id].to_i

        text_data << "Updated pallet_sequences #{pallet_sequence_id} : #{attrs}"
        if debug_mode
          p "Updated pallet_sequences #{pallet_sequence_id} : #{attrs}"
        else
          DB.transaction do
            p "Updated pallet_sequences #{pallet_sequence_id} : #{attrs}"
            DB[:pallet_sequences].where(id: pallet_sequence_id).update(attrs)
            log_status(:pallet_sequences, pallet_sequence_id, 'RESTORED BULK PRODUCTION RUN UPDATE PALLET SEQUENCE DATA', user_name: 'System')
          end
        end
      end
    end

    infodump = <<~STR
      Script: FixPalletSequenceBulkProductionRunUpdate

      What this script does:
      ----------------------
      1. loops through all reworks runs where the run type is BULK PRODUCTION RUN UPDATE.
      2. for each rework, grab the list of affected pallets and before_state.
      3. reverses update on sequences where production_run_id != from_production_run_id (reworks_run[:before_state].to_h[:production_run_id])
      4. log status for each pallet sequences.

      Reason for this script:
      -----------------------
      BULK PRODUCTION RUN UPDATE RUN_TYPE - should only update sequences where production_run_id = from_production_run_id

      Results:
      --------
      data: Updated reworks_runs(#{reworks_run_ids.join(',')})

      text data:
      #{text_data.join("\n")}
    STR

    log_infodump(:data_fix,
                 :pallet_sequences,
                 :production_run_attrs_update,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Updated pallet_sequences successfully')
    end
  end

  def get_audit_before_state(pallet_sequence_id)
    query = <<~SQL
      SELECT DISTINCT row_data_id,
             row_data -> 'production_run_id' AS production_run_id,
             row_data -> 'packhouse_resource_id' AS packhouse_resource_id,
             row_data -> 'production_line_id' AS production_line_id,
             row_data -> 'farm_id' AS farm_id,
             row_data -> 'puc_id' AS puc_id,
             row_data -> 'orchard_id' AS orchard_id,
             row_data -> 'cultivar_group_id' AS cultivar_group_id,
             row_data -> 'cultivar_id' AS cultivar_id,
             row_data -> 'season_id' AS season_id,
             row_data -> 'marketing_puc_id' AS marketing_puc_id,
             row_data -> 'marketing_orchard_id' AS marketing_orchard_id,
             logged_actions.event_id
      FROM audit.logged_actions
      LEFT JOIN audit.logged_action_details ON logged_action_details.transaction_id = logged_actions.transaction_id
      WHERE table_name = 'pallet_sequences'
       AND action = 'U'
       AND row_data_id = #{pallet_sequence_id}
       AND route_url = '/production/reworks/reworks_run_types/56/reworks_runs/multiselect_reworks_run_bulk_production_run_update'
       ORDER BY logged_actions.event_id;
    SQL
    DB[query].first
  end

  def resolve_before_state_attrs(rec)
    { production_run_id: rec[:production_run_id],
      packhouse_resource_id: rec[:packhouse_resource_id],
      production_line_id: rec[:production_line_id],
      farm_id: rec[:farm_id],
      puc_id: rec[:puc_id],
      orchard_id: rec[:orchard_id],
      cultivar_group_id: rec[:cultivar_group_id],
      cultivar_id: rec[:cultivar_id],
      season_id: rec[:season_id],
      marketing_puc_id: rec[:marketing_puc_id],
      marketing_orchard_id: rec[:marketing_orchard_id] }
  end
end
