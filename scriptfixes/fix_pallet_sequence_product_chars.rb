# frozen_string_literal: true

# What this script does:
# ----------------------
# Loop through carton_labels and update pallet_sequences.product_chars
#
# Reason for this script:
# -----------------------
# pull through product_chars from carton_labels to pallet_sequences
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb FixPalletSequenceProductChars
# Live  : RACK_ENV=production ruby scripts/base_script.rb FixPalletSequenceProductChars
# Dev   : ruby scripts/base_script.rb FixPalletSequenceProductChars
#
class FixPalletSequenceProductChars < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    query = <<~SQL
      SELECT DISTINCT ps.id AS pallet_sequence_id,
                      carton_labels.product_chars
      FROM pallet_sequences ps
      JOIN cartons ON
        CASE
          WHEN ps.scanned_from_carton_id IS NULL THEN cartons.pallet_sequence_id = ps.id
          ELSE cartons.id = ps.scanned_from_carton_id
        END
      JOIN carton_labels ON carton_labels.id = cartons.carton_label_id AND carton_labels.product_chars IS NOT NULL
      WHERE ps.product_chars IS NULL
    SQL
    pallet_sequences = DB[query].select_map(%i[pallet_sequence_id product_chars])
    return failed_response('There are no pallet_sequences with missing product_chars') if pallet_sequences.nil_or_empty?

    p "Records affected: #{pallet_sequences.count}"
    pallet_sequences.each do |pallet_sequence_id, product_chars|
      attrs = { product_chars: product_chars }
      if debug_mode
        p "Updated pallet_sequences #{pallet_sequence_id}: #{attrs}"
      else
        DB.transaction do
          p "Updated pallet_sequences #{pallet_sequence_id}: #{attrs}"
          DB[:pallet_sequences].where(id: pallet_sequence_id).update(attrs)
        end
      end
    end

    infodump = <<~STR
      Script: FixPalletSequenceProductChars

      What this script does:
      ----------------------
      Loop through carton_labels and update pallet_sequences.product_chars

      Reason for this script:
      -----------------------
      Pull through product_chars from carton_labels to pallet_sequences

      Results:
      --------

       Updated #{pallet_sequences.count} pallet_sequences.
    STR

    log_infodump(:data_fix,
                 :product_chars,
                 :update_pallet_sequences_product_chars,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Updated pallet_sequences product_chars successfully')
    end
  end
end
