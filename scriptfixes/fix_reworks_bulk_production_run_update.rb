# frozen_string_literal: true

# What this script does:
# ----------------------
# 1. loops through all reworks runs where the run type is BULK PRODUCTION RUN UPDATE.
# 2. for each rework, grab the list of affected pallets and and apply the relevant changes to the pallet sequences.
# 3. Log status for each pallet sequences.
#
# Reason for this script:
# -----------------------
# problem in the code
#
class FixReworksBulkProductionRunUpdate < BaseScript
  def run  # rubocop:disable Metrics/AbcSize
    query = <<~SQL
      SELECT reworks_runs.id,pallets_affected,COALESCE(reworks_runs.changes_made -> 'pallets' -> 'pallet_sequences' -> 'changes' -> 'after', null) AS after_state
      FROM reworks_runs
      JOIN reworks_run_types ON reworks_run_types.id = reworks_runs.reworks_run_type_id
      WHERE run_type = 'BULK PRODUCTION RUN UPDATE'
      ORDER BY id
    SQL
    reworks_runs = DB[query].all
    return failed_response("There are no #{AppConst::REWORKS_ACTION_BULK_PRODUCTION_RUN_UPDATE} reworks_runs to fix") if reworks_runs.empty?

    reworks_run_ids = reworks_runs.map { |r| r[:id] }
    p "Records affected: #{reworks_run_ids.count}"

    text_data = []
    reworks_runs.each do |reworks_run|
      pallet_numbers = reworks_run[:pallets_affected][0].gsub(/['"]/, '').split("\n")
      pallet_numbers = pallet_numbers.map(&:strip).reject(&:empty?)
      attrs = reworks_run[:after_state].to_h
      pallet_sequence_ids = DB["SELECT id FROM pallet_sequences WHERE pallet_number IN ('#{pallet_numbers.join('\',\'')}') AND pallet_id IS NOT NULL"].map { |r| r[:id] } unless pallet_numbers.nil_or_empty?
      text_data << "updated Pallet sequences #{pallet_sequence_ids.join(',')} : #{attrs}"

      if debug_mode
        p "Updated pallet_sequences #{pallet_sequence_ids.join(',')} : #{attrs}"
      else
        DB.transaction do
          p "Updated pallet_sequences #{pallet_sequence_ids.join(',')} : #{attrs}"
          DB[:pallet_sequences].where(id: pallet_sequence_ids).update(attrs)
          log_status(:reworks_runs, reworks_run[:id], 'FIXED BULK PRODUCTION RUN UPDATE PALLET SEQUENCE DATA', comment: 'because of problem in the code', user_name: 'System')
          log_multiple_statuses(:pallet_sequences, pallet_sequence_ids, 'FIXED BULK PRODUCTION RUN UPDATE PALLET SEQUENCE DATA', comment: 'because of problem in the code', user_name: 'System')
        end
      end
    end

    infodump = <<~STR
      Script: FixReworksBulkProductionRunUpdate

      What this script does:
      ----------------------
      1. loops through all reworks runs where the run type is BULK PRODUCTION RUN UPDATE.
      2. for each rework, grab the list of affected pallets and and apply the relevant changes to the pallet sequences.
      3. Log status for each pallet sequences.

      Reason for this script:
      -----------------------
      problem in the code

      Results:
      --------
      data: Updated reworks_runs(#{reworks_run_ids.join(',')})

      text data:
      #{text_data.join("\n")}
    STR

    log_infodump(:data_fix,
                 :reworks_runs,
                 :fix_reworks_bulk_production_run_update,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('fixed reworks_bulk_production_run_update data')
    end
  end
end
