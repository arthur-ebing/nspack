# frozen_string_literal: true

# What this script does:
# ----------------------
# Finds and updates pallets and pallet_sequences where (fn_calculate_pallet_nett_weight(id, gross_weight)-nett_weight) is not zero
#
# Reason for this script:
# -----------------------
# There was a bug in the nett weight calculation on the fn_pallet_seq_nett_weight_calc trigger
#
class FixPalletNettWeights < BaseScript
  def run  # rubocop:disable Metrics/AbcSize
    query = <<~SQL
      SELECT id FROM pallets
       WHERE gross_weight IS NOT NULL
        AND id IN ( SELECT id FROM pallets
                              WHERE (fn_calculate_pallet_nett_weight(id, gross_weight)-nett_weight) <>  0
      );
    SQL
    pallets = DB[query].all
    return failed_response('There are no pallet nett weights to fix') if pallets.empty?

    pallet_ids = pallets.map { |r| r[:id] }
    p "Records affected: #{pallet_ids.count}"

    attrs = { re_calculate_nett: true }
    pallet_sequence_ids = DB["SELECT id FROM pallet_sequences WHERE pallet_id IN (#{pallet_ids.join(',')})"].map { |r| r[:id] }

    str = "updated pallet : #{pallet_ids} : #{attrs}
           pallet_sequences : #{pallet_sequence_ids.join(',')}\n"

    if debug_mode
      p str
    else
      DB.transaction do
        p str
        DB[:pallets].where(id: pallet_ids).update(attrs)
        log_multiple_statuses(:pallets, pallet_ids, 'FIXED NETT WEIGHT BUG', user_name: 'System')
        log_multiple_statuses(:pallet_sequences, pallet_sequence_ids, 'FIXED NETT WEIGHT BUG', user_name: 'System')
      end
    end

    infodump = <<~STR
      Script: FixPalletNettWeights

      What this script does:
      ----------------------
      Finds and updates pallets and pallet_sequences where (fn_calculate_pallet_nett_weight(id, gross_weight)-nett_weight) is not zero

      Reason for this script:
      -----------------------
      There was a bug in the nett weight calculation on the fn_pallet_seq_nett_weight_calc trigger

      Results:
      --------
      #{str}
    STR

    unless pallets.nil_or_empty?
      log_infodump(:data_fix,
                   :nett_weight,
                   :update_pallet_nett_weight,
                   infodump)
    end

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Pallets and pallet_sequences nett weights updated successfully')
    end
  end
end
