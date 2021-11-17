# frozen_string_literal: true

# What this script does:
# ----------------------
# Finds and updates depot pallets' gross_weight and derived_weight flag
# Force a trigger event to recalculate nett weight by incrementing carton_quantity, then immediately decrementing it
# Log status on pallet and sequence: NETT_WEIGHT_CALC_FORCED
#
# Reason for this script:
# -----------------------
# Depot pallets created with lacking/erroneous weight info
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb RecalcDepotPalletNettWeights
# Live  : RACK_ENV=production ruby scripts/base_script.rb RecalcDepotPalletNettWeights
# Dev   : ruby scripts/base_script.rb RecalcDepotPalletNettWeights
#
class RecalcDepotPalletNettWeights < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    query = <<~SQL
      SELECT pallet_sequences.id, pallet_sequences.pallet_id
      FROM pallets
      JOIN pallet_sequences ON pallets.id = pallet_sequences.pallet_id
      JOIN standard_pack_codes ON pallet_sequences.standard_pack_code_id = standard_pack_codes.id
      WHERE (pallets.gross_weight IS NOT NULL OR pallet_sequences.nett_weight IS NULL)
      AND pallets.depot_pallet
      ORDER BY pallets.id DESC;
    SQL
    pallets = DB[query].all
    return failed_response('There are no pallet nett weights to fix') if pallets.empty?

    pallet_ids = pallets.map { |r| r[:pallet_id] }.uniq
    pallet_sequence_ids = pallets.map { |r| r[:id] }
    p "#{pallet_ids.count} pallets affected"
    p "#{pallet_sequence_ids.count} pallet sequences affected"

    attrs = { gross_weight: nil, derived_weight: true }
    str = "updated pallet : #{pallet_ids} : #{attrs}
                   pallet_sequences : #{pallet_sequence_ids}"

    if debug_mode
      p str
    else
      DB.transaction do
        DB[:pallets].where(id: pallet_ids).update(attrs)
        increment_pallet_sequence_carton_quantities(pallet_sequence_ids)
        decrement_pallet_sequence_carton_quantities(pallet_sequence_ids)
        log_multiple_statuses(:pallets, pallet_ids, 'NETT_WEIGHT_CALC_FORCED', user_name: 'System')
        log_multiple_statuses(:pallet_sequences, pallet_sequence_ids, 'NETT_WEIGHT_CALC_FORCED', user_name: 'System')
      end
    end

    unless pallets.nil_or_empty?
      infodump = <<~STR
        Script: RecalcDepotPalletNettWeights

        What this script does:
        ----------------------
        Finds and updates depot pallets' gross_weight and derived_weight flag
        Force a trigger event to recalculate nett weight by incrementing carton_quantity, then immediately decrementing it
        Log status on pallet and sequence: NETT_WEIGHT_CALC_FORCED

        Reason for this script:
        -----------------------
        Depot pallets created with lacking/erroneous weight info

        Results:
        --------
        #{str}
      STR

      log_infodump(:data_fix,
                   :nett_weight,
                   :recalc_depot_pallet_nett_weights,
                   infodump)
    end

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Pallets and pallet_sequences nett weights updated successfully')
    end
  end

  def increment_pallet_sequence_carton_quantities(pallet_sequence_ids)
    query = <<~SQL
      UPDATE pallet_sequences
      SET carton_quantity = carton_quantity + 1
      WHERE pallet_sequences.id IN ?
    SQL
    DB[query, pallet_sequence_ids].update
  end

  def decrement_pallet_sequence_carton_quantities(pallet_sequence_ids)
    query = <<~SQL
      UPDATE pallet_sequences
      SET carton_quantity = carton_quantity - 1
      WHERE pallet_sequences.id IN ?
    SQL
    DB[query, pallet_sequence_ids].update
  end
end
