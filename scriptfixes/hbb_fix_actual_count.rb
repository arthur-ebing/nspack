# frozen_string_literal: true

# What this script does:
# ----------------------
# Updates the actual count for JUMBLE cartons and pallet_sequences to 162 where production_run_id is 46 & 47.
#
# Reason for this script:
# -----------------------
# Cartons with missing Actual Count doesn't generate through to the Incentive Report
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb HBBFixActualCount production_run_id
# Live  : RACK_ENV=production ruby scripts/base_script.rb HBBFixActualCount production_run_id
# Dev   : ruby scripts/base_script.rb HBBFixActualCount production_run_id
#
class HBBFixActualCount < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    resolve_args
    carton_label_ids = DB[:carton_labels]
                       .where(production_run_id: @production_run_id)
                       .where(packing_method_id: @packing_method_id)
                       .where(fruit_actual_counts_for_pack_id: nil)
                       .select_map(:id).uniq
    p "carton_label_ids to update: #{carton_label_ids}"

    pallet_sequence_ids = DB[:pallet_sequences]
                          .where(fruit_actual_counts_for_pack_id: nil)
                          .where(scanned_from_carton_id: DB[:cartons]
                                       .where(carton_label_id: carton_label_ids)
                                       .select_map(:id).uniq)
                          .select_map(:id).uniq
    p "pallet_sequence_ids to update: #{pallet_sequence_ids}"

    if debug_mode
      p 'Updated Jumble cartons and pallet_sequences successfully'
    else
      DB.transaction do # rubocop:disable Metrics/BlockLength
        cl_upd = <<~SQL
          UPDATE carton_labels
          SET std_fruit_size_count_id = t.std_fruit_size_count_id,
              fruit_actual_counts_for_pack_id = t.fruit_actual_counts_for_pack_id
          FROM (
            SELECT sc.id AS std_fruit_size_count_id, ac.id AS fruit_actual_counts_for_pack_id, cl.id AS carton_label_id
            FROM std_fruit_size_counts sc
            JOIN cultivar_groups ON sc.commodity_id = cultivar_groups.commodity_id
            AND size_count_value = #{@actual_count}
            JOIN fruit_actual_counts_for_packs ac ON ac.std_fruit_size_count_id = sc.id
            JOIN carton_labels cl ON cl.basic_pack_code_id = ac.basic_pack_code_id
            AND cl.id IN (#{carton_label_ids.join(',')})
          ) t
          WHERE carton_labels.id = t.carton_label_id;
        SQL
        DB.run(cl_upd) unless carton_label_ids.nil_or_empty?

        ps_upd = <<~SQL
          UPDATE pallet_sequences
          SET std_fruit_size_count_id = t.std_fruit_size_count_id,
              fruit_actual_counts_for_pack_id = t.fruit_actual_counts_for_pack_id
          FROM (
            SELECT sc.id AS std_fruit_size_count_id, ac.id AS fruit_actual_counts_for_pack_id, ps.id AS pallet_sequence_id
            FROM std_fruit_size_counts sc
            JOIN cultivar_groups ON sc.commodity_id = cultivar_groups.commodity_id
            AND size_count_value = #{@actual_count}
            JOIN fruit_actual_counts_for_packs ac ON ac.std_fruit_size_count_id = sc.id
            JOIN pallet_sequences ps ON ps.basic_pack_code_id = ac.basic_pack_code_id
            AND ps.id IN (#{pallet_sequence_ids.join(',')})
          ) t
          WHERE pallet_sequences.id = t.pallet_sequence_id;
        SQL
        DB.run(ps_upd) unless pallet_sequence_ids.nil_or_empty?
      end
    end

    infodump = <<~STR
      Script: HBBFixActualCount

      What this script does:
      ----------------------
      Updates the actual count for JUMBLE cartons and pallet_sequences to #{@actual_count} where production_run_id is 46 & 47.

      Reason for this script:
      -----------------------
      Cartons with missing Actual Count doesn't generate through to the Incentive Report

      Results:
      --------
      Updated Jumble cartons and pallet_sequences' fruit_actual_counts_for_pack_id for production runs 46 and 47

      carton_labels: #{carton_label_ids.join(', ')}

      pallet_sequences: #{pallet_sequence_ids.join(', ')}
    STR

    log_infodump(:data_fix,
                 :hbb_fix_actual_count,
                 :update_actual_count,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Actual Count updated successfully')
    end
  end

  def resolve_args
    @production_run_id = DB[:production_runs].where(id: args[0]).get(:id)
    raise ArgumentError, 'Production Run not found' if @production_run_id.nil?

    @packing_method_id = DB[:packing_methods].where(packing_method_code: 'JUMBLE').get(:id)
    raise ArgumentError, 'Packing method not found' if @packing_method_id.nil?

    @actual_count = 162
    p "@production_run_id: #{@production_run_id}"
    p "@packing_method_id: #{@packing_method_id}"
    p "@actual_count: #{@actual_count}"
  end
end
