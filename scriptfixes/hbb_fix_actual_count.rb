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
    resolve_run_objects
    commodity_id = DB[:cultivar_groups]
                   .where(id: DB[:production_runs]
                                .where(id: @production_run_id)
                                .get(:cultivar_group_id))
                   .get(:commodity_id)

    query = <<~SQL
      SELECT f.basic_pack_code_id, f.id, f.std_fruit_size_count_id
      FROM fruit_actual_counts_for_packs f
      JOIN std_fruit_size_counts s ON s.id = f.std_fruit_size_count_id
      WHERE f.actual_count_for_pack = #{@actual_count}
        AND s.commodity_id = #{commodity_id}
    SQL
    sizes = DB[query].all

    if debug_mode
      p 'Updated Jumble cartons and pallet_sequences successfully'
    else
      DB.transaction do
        sizes.each do |size|
          update_cartons_with_ids_matching_on_basic_pack(size) unless @carton_label_ids.nil_or_empty?
          update_sequences_with_ids_matching_on_basic_pack(size) unless @pallet_sequence_ids.nil_or_empty?
        end
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

      carton_labels: #{@carton_label_ids.join(', ')}

      pallet_sequences: #{@pallet_sequence_ids.join(', ')}
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

  def resolve_run_objects # rubocop:disable Metrics/AbcSize
    @carton_label_ids = DB[:carton_labels]
                        .where(production_run_id: @production_run_id)
                        .where(packing_method_id: @packing_method_id)
                        .where(fruit_actual_counts_for_pack_id: nil)
                        .select_map(:id).uniq
    p "@carton_label_ids to update: #{@carton_label_ids}"

    @pallet_sequence_ids = DB[:pallet_sequences]
                           .where(fruit_actual_counts_for_pack_id: nil)
                           .where(scanned_from_carton_id: DB[:cartons]
                                       .where(carton_label_id: @carton_label_ids)
                                       .select_map(:id).uniq)
                           .select_map(:id).uniq
    p "@pallet_sequence_ids to update: #{@pallet_sequence_ids}"
  end

  def update_cartons_with_ids_matching_on_basic_pack(atrrs)
    cl_upd = <<~SQL
      UPDATE carton_labels
      SET std_fruit_size_count_id = #{atrrs[:std_fruit_size_count_id]},
          fruit_actual_counts_for_pack_id = #{atrrs[:id]}
      WHERE carton_labels.id IN (#{@carton_label_ids.join(',')})
      AND basic_pack_code_id = #{atrrs[:basic_pack_code_id]};
    SQL
    DB.run(cl_upd)
  end

  def update_sequences_with_ids_matching_on_basic_pack(atrrs)
    ps_upd = <<~SQL
      UPDATE pallet_sequences
      SET std_fruit_size_count_id = #{atrrs[:std_fruit_size_count_id]},
          fruit_actual_counts_for_pack_id = #{atrrs[:id]}
      WHERE pallet_sequences.id IN (#{@pallet_sequence_ids.join(',')})
      AND basic_pack_code_id = #{atrrs[:basic_pack_code_id]};
    SQL
    DB.run(ps_upd)
  end
end
