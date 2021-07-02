# frozen_string_literal: true

# What this script does:
# ----------------------
# Loop through repacked pallets that has_individual_cartons true and update its cartons.pallet_sequence_id
#
# Reason for this script:
# -----------------------
# update cartons.pallet_sequence_id to repacked pallet_sequence_id if pallet.has_individual_cartons
#
class FixCartonPalletSequence < BaseScript
  def run # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    query = <<~SQL
      SELECT pallet_sequences.id, pallet_sequences.repacked_from_pallet_id,
      pallet_sequences.pallet_sequence_number
      FROM pallets
      JOIN pallet_sequences ON pallets.id = pallet_sequences.pallet_id
      WHERE pallets.repacked
      AND pallets.has_individual_cartons;
    SQL
    sequences = DB[query].select_map(%i[id repacked_from_pallet_id pallet_sequence_number])
    return failed_response('There are no repacked pallets to fix') if sequences.empty?

    puts "Records affected: #{sequences.count}"

    updates = []

    sequences.each do |sequence_id, repacked_from_pallet_id, pallet_sequence_number|
      next if DB[:cartons].where(pallet_sequence_id: sequence_id).count.positive?

      @carton_ids = []
      repacked_from_pallet_cartons(repacked_from_pallet_id, pallet_sequence_number)
      puts "Pallet sequence id: #{sequence_id}. Cartons:"
      @carton_ids = @carton_ids.flatten
      p @carton_ids

      next if @carton_ids.count.zero?

      updates << { carton_ids: @carton_ids.dup, seq_id: sequence_id }
    end

    if debug_mode
      puts "Updated cartons on #{updates.length} pallet sequences."
    else
      DB.transaction do
        updates.each do |data|
          attrs = { pallet_sequence_id: data[:seq_id] }
          DB[:cartons].where(id: data[:carton_ids]).update(attrs)
          log_multiple_statuses(:cartons, data[:carton_ids], 'FIXED CARTON PALLET SEQUENCE IDS', comment: "sequence id: #{data[:seq_id]}", user_name: 'System')
        end
      end
    end

    infodump = <<~STR
      Script: FixCartonPalletSequence

      What this script does:
      ----------------------
      Loop through repacked pallets that has_individual_cartons true and update its cartons.pallet_sequence_id

      Reason for this script:
      -----------------------
      update cartons.pallet_sequence_id to repacked pallet_sequence_id if pallet.has_individual_cartons

      Results:
      --------
      Selected #{sequences.length} repacked pallet sequences.

      Updates:
      #{updates.inspect.split('}, ').join("},\n")}
    STR

    unless sequences.nil_or_empty?
      log_infodump(:data_fix,
                   :repacked_pallets,
                   :update_cartons_pallet_sequence_id,
                   infodump)
    end

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Cartons pallet_sequence_id updated successfully')
    end
  end

  private

  def repacked_from_pallet_cartons(pallet_id, pallet_sequence_number) # rubocop:disable Metrics/AbcSize
    sequence_id = DB[:pallet_sequences]
                  .where(scrapped_from_pallet_id: pallet_id)
                  .where(pallet_sequence_number: pallet_sequence_number)
                  .get(:id)
    @carton_ids << DB[:cartons].where(pallet_sequence_id: sequence_id).map(:id)

    repacked_from_pallet_id = DB[:pallets]
                              .join(:pallet_sequences, scrapped_from_pallet_id: :id)
                              .where(Sequel[:pallets][:id] => pallet_id)
                              .where(:has_individual_cartons)
                              .get(:repacked_from_pallet_id)

    return if repacked_from_pallet_id.nil_or_empty?

    repacked_from_pallet_cartons(repacked_from_pallet_id, pallet_sequence_number)
  end
end
