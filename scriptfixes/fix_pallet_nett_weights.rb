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
  def run  # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    query = <<~SQL
      SELECT id, pallet_number, fn_calculate_pallet_nett_weight(id, gross_weight) AS calculated_nett_weight, nett_weight,
             carton_quantity AS plt_carton_quantity
      FROM pallets WHERE id IN ( SELECT id FROM pallets
                                 WHERE (fn_calculate_pallet_nett_weight(id, gross_weight)-nett_weight) <>  0
      );
    SQL
    pallets = DB[query].all
    return failed_response('There are no pallet nett weights to fix') if pallets.empty?

    pallet_ids = pallets.map { |r| r[:id] }
    p "Records affected: #{pallet_ids.count}"

    text_data = []
    update_ps_query = []
    pallets.each do |pallet| # rubocop:disable Metrics/BlockLength
      diff = pallet[:calculated_nett_weight] - pallet[:nett_weight]
      next if diff.nil?

      pallet_id = pallet[:id]
      pallet_attrs = { nett_weight: pallet[:calculated_nett_weight] }

      pallet_sequence_ids = DB["SELECT id FROM pallet_sequences WHERE pallet_id = #{pallet_id}"].map { |r| r[:id] }
      unless pallet_sequence_ids.nil_or_empty?
        update_ps_str = <<~SQL
          UPDATE pallet_sequences SET nett_weight = ((carton_quantity / #{pallet[:plt_carton_quantity]}::numeric) * #{pallet[:calculated_nett_weight]})::numeric
          WHERE id IN (#{pallet_sequence_ids.join(',')}) AND carton_quantity <> 0;
        SQL
      end

      str = "updated pallet : #{pallet_id} : #{pallet_attrs}
             pallet_sequences : #{pallet_sequence_ids.join(',')}
             update_query : #{update_ps_str}\n"

      text_data << str
      update_ps_query << update_ps_str

      if debug_mode
        p str
      else
        DB.transaction do
          p str
          DB[:pallets].where(id: pallet_id).update(pallet_attrs)
          DB[update_ps_query.join("\n")].update unless update_ps_query.nil_or_empty?
          log_status(:pallets, pallet_id, 'FIXED NETT WEIGHT BUG', user_name: 'System')
          log_multiple_statuses(:pallet_sequences, pallet_sequence_ids.uniq, 'FIXED NETT WEIGHT BUG', user_name: 'System')
        end
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
      #{text_data.join("\n\n")}
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
