# frozen_string_literal: true

# require 'logger'
class PalletSequencesPhytoData < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    query = <<~SQL
      SELECT DISTINCT
          ps.id AS pallet_sequence_id,
          vw.api_result AS new_phyto_data
      FROM
          pallet_sequences ps
          JOIN vw_orchard_test_results_flat vw ON ps.puc_id = vw.puc_id
           AND ps.orchard_id = vw.orchard_id
           AND ps.cultivar_id = vw.cultivar_id
      WHERE
          api_attribute = 'phytoData'
          AND ps.phyto_data <> vw.api_result
    SQL
    pallet_sequences = DB[query].select_map(%i[pallet_sequence_id new_phyto_data])
    pallet_sequence_ids = DB[query].select_map(%i[pallet_sequence_id])

    p "Records affected: #{pallet_sequences.count}"
    pallet_sequences.each do |pallet_sequence_id, new_phyto_data|
      attrs = { phyto_data: new_phyto_data }
      if debug_mode
        p "Updated row #{pallet_sequence_id}: #{attrs}"
      else
        DB.transaction do
          p "Updated row #{pallet_sequence_id}: #{attrs}"
          DB[:pallet_sequences].where(id: pallet_sequence_id).update(attrs)
        end
      end
    end

    log_infodump(:data_fix,
                 :pallet_sequences,
                 :set_phyto_data,
                 "Updated pallet_sequences phyto_data for pallet_sequence_ids:#{pallet_sequence_ids}")

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Data Updated')
    end
  end
end
