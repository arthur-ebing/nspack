# frozen_string_literal: true

# What this script does:
# ----------------------
# Fix pallets where the build status is not correct based on the cartons per pallet and no of cartons on the pallet.
#
# Reason for this script:
# -----------------------
# The trigger on pallet sequences that leads to the re-calculation of the pallet build status had a bug
# which caused the wrong cartons per pallet id to be used to find the required cartons per pallet amount.
# This meant that the comparison of total cartons to required cartons per pallet was almost always wrong
# and so the status was usually set incorrectly.
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb FixPalletBuildStatus
# Live  : RACK_ENV=production ruby scripts/base_script.rb FixPalletBuildStatus
# Dev   : ruby scripts/base_script.rb FixPalletBuildStatus
#
class FixPalletBuildStatus < BaseScript # rubocop:disable Metrics/ClassLength
  # Update build status to 'FULL', palletized = true, partially_palletized = false where fn_calculate_pallet_build_status = 'FULL' && current status = 'OVERFULL' returning id
  # Update palletized_at, set to partial_palletized_at if palletized_at is null for the returned ids
  # Log status for those ids: 'FIX BUILD STATUS', comment 'From OVERFULL to FULL'
  # Update build status to 'FULL', palletized = true, partially_palletized = false where fn_calculate_pallet_build_status = 'FULL' && current status = 'PARTIAL' returning id
  # Update palletized_at, set to partial_palletized_at if palletized_at is null for the returned ids
  # Log status for those ids: 'FIX BUILD STATUS', comment 'From 'PARTIAL to FULL'
  # Update build status to 'PARTIAL', palletized = false, partially_palletized = true where fn_calculate_pallet_build_status = 'PARTIAL' && current status = 'FULL' returning id
  # Update partial_palletized_at, set to palletized_at if partial_palletized_at is null for the returned ids
  # Log status for those ids: 'FIX BUILD STATUS', comment 'From FULL to PARTIAL'
  # Update build status to 'PARTIAL', palletized = false, partially_palletized = true where fn_calculate_pallet_build_status = 'PARTIAL' && current status = 'OVERFULL' returning id
  # Update partial_palletized_at, set to palletized_at if partial_palletized_at is null for the returned ids
  # Log status for those ids: 'FIX BUILD STATUS', comment 'From OVERFULL to PARTIAL'
  # Update build status to 'OVERFULL', palletized = true, partially_palletized = false where fn_calculate_pallet_build_status = 'OVERFULL' && current status = 'FULL' returning id
  # Update palletized_at, set to partial_palletized_at if palletized_at is null for the returned ids
  # Log status for those ids: 'FIX BUILD STATUS', comment 'From FULL to OVERFULL'
  # Update build status to 'OVERFULL', palletized = true, partially_palletized = false where fn_calculate_pallet_build_status = 'OVERFULL' && current status = 'PARTIAL' returning id
  # Update palletized_at, set to partial_palletized_at if palletized_at is null for the returned ids
  # Log status for those ids: 'FIX BUILD STATUS', comment 'From 'PARTIAL to OVERFULL'

  def run # rubocop:disable Metrics/AbcSize
    # Do some work here...

    logs = []
    query = <<~SQL
      UPDATE pallets
      SET build_status = ?, palletized = ?, partially_palletized = ?
      WHERE fn_calculate_pallet_build_status(carton_quantity,
            (SELECT cartons_per_pallet FROM cartons_per_pallet WHERE id = (SELECT cartons_per_pallet_id
             FROM pallet_sequences
             WHERE id = (SELECT id
                   FROM pallet_sequences
                   WHERE pallet_id = pallets.id
                     AND scrapped_at IS NULL
                   ORDER BY pallet_sequence_number
                   LIMIT 1)))) = ?
      AND build_status = ?
      AND NOT scrapped
    SQL
    sel_query = <<~SQL
      SELECT id
      FROM pallets
      WHERE fn_calculate_pallet_build_status(carton_quantity,
            (SELECT cartons_per_pallet FROM cartons_per_pallet WHERE id = (SELECT cartons_per_pallet_id
             FROM pallet_sequences
             WHERE id = (SELECT id
                   FROM pallet_sequences
                   WHERE pallet_id = pallets.id
                     AND scrapped_at IS NULL
                   ORDER BY pallet_sequence_number
                   LIMIT 1)))) = ?
      AND build_status = ?
      AND NOT scrapped
    SQL

    DB.transaction do # rubocop:disable Metrics/BlockLength
      ids = DB[sel_query, 'FULL', 'OVERFULL'].select_map(:id)
      ds1 = DB[query, 'FULL', true, false, 'FULL', 'OVERFULL']
      no_upd = ds1.update
      ds2 = DB['UPDATE pallets SET palletized_at = partially_palletized_at WHERE id IN ? AND palletized_at IS NULL', ids]
      no_upd2 = ds2.update
      log_multiple_statuses(:pallets, ids, 'FIX BUILD STATUS', comment: 'From OVERFULL to FULL', user_name: 'System')
      logs << "Changed build status from OVERFULL to FULL for #{ids.length} (#{no_upd}, #{no_upd2}) pallets: #{ids.inspect}"

      ids = DB[sel_query, 'FULL', 'PARTIAL'].select_map(:id)
      ds1 = DB[query, 'FULL', true, false, 'FULL', 'PARTIAL']
      no_upd = ds1.update
      ds2 = DB['UPDATE pallets SET palletized_at = partially_palletized_at WHERE id IN ? AND palletized_at IS NULL', ids]
      no_upd2 = ds2.update
      log_multiple_statuses(:pallets, ids, 'FIX BUILD STATUS', comment: 'From PARTIAL to FULL', user_name: 'System')
      logs << "Changed build status from PARTIAL to FULL for #{ids.length} (#{no_upd}, #{no_upd2}) pallets: #{ids.inspect}"

      ids = DB[sel_query, 'PARTIAL', 'FULL'].select_map(:id)
      ds1 = DB[query, 'PARTIAL', false, true, 'PARTIAL', 'FULL']
      no_upd = ds1.update
      ds2 = DB['UPDATE pallets SET partially_palletized_at = palletized_at WHERE id IN ? AND partially_palletized_at IS NULL', ids]
      no_upd2 = ds2.update
      log_multiple_statuses(:pallets, ids, 'FIX BUILD STATUS', comment: 'From FULL to PARTIAL', user_name: 'System')
      logs << "Changed build status from FULL to PARTIAL for #{ids.length} (#{no_upd}, #{no_upd2}) pallets: #{ids.inspect}"

      ids = DB[sel_query, 'PARTIAL', 'OVERFULL'].select_map(:id)
      ds1 = DB[query, 'PARTIAL', false, true, 'PARTIAL', 'OVERFULL']
      no_upd = ds1.update
      ds2 = DB['UPDATE pallets SET partially_palletized_at = palletized_at WHERE id IN ? AND partially_palletized_at IS NULL', ids]
      no_upd2 = ds2.update
      log_multiple_statuses(:pallets, ids, 'FIX BUILD STATUS', comment: 'From OVERFULL to PARTIAL', user_name: 'System')
      logs << "Changed build status from OVERFULL to PARTIAL for #{ids.length} (#{no_upd}, #{no_upd2}) pallets: #{ids.inspect}"

      ids = DB[sel_query, 'OVERFULL', 'FULL'].select_map(:id)
      ds1 = DB[query, 'OVERFULL', true, false, 'OVERFULL', 'FULL']
      no_upd = ds1.update
      ds2 = DB['UPDATE pallets SET palletized_at = partially_palletized_at WHERE id IN ? AND palletized_at IS NULL', ids]
      no_upd2 = ds2.update
      log_multiple_statuses(:pallets, ids, 'FIX BUILD STATUS', comment: 'From FULL to OVERFULL', user_name: 'System')
      logs << "Changed build status from FULL to OVERFULL for #{ids.length} (#{no_upd}, #{no_upd2}) pallets: #{ids.inspect}"

      ids = DB[sel_query, 'OVERFULL', 'PARTIAL'].select_map(:id)
      ds1 = DB[query, 'OVERFULL', true, false, 'OVERFULL', 'PARTIAL']
      no_upd = ds1.update
      ds2 = DB['UPDATE pallets SET palletized_at = partially_palletized_at WHERE id IN ? AND palletized_at IS NULL', ids]
      no_upd2 = ds2.update
      log_multiple_statuses(:pallets, ids, 'FIX BUILD STATUS', comment: 'From PARTIAL to OVERFULL', user_name: 'System')
      logs << "Changed build status from PARTIAL to OVERFULL for #{ids.length} (#{no_upd}, #{no_upd2}) pallets: #{ids.inspect}"

      puts logs.join("\n")
      raise Crossbeams::InfoError, 'Cancel update for debug mode' if debug_mode
    end

    infodump = <<~STR
      Script: FixPalletBuildStatus

      What this script does:
      ----------------------
      Fix pallets where the build status is not correct based on the cartons per pallet and no of cartons on the pallet.

      Reason for this script:
      -----------------------
      The trigger on pallet sequences that leads to the re-calculation of the pallet build status had a bug
      which caused the wrong cartons per pallet id to be used to find the required cartons per pallet amount.
      This meant that the comparison of total cartons to required cartons per pallet was almost always wrong
      and so the status was usually set incorrectly.

      Results:
      --------
      Updated something

      data: #{logs.join("\n")}
    STR

    log_infodump(:data_fix,
                 :pallet_build_status,
                 :fix_full_partial_overfull,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Build status fix run')
    end
  end
end
