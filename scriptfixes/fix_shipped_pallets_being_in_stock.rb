# frozen_string_literal: true

# What this script does:
# ----------------------
# Sets all shipped pallets in_stock to false
#
# Reason for this script:
# -----------------------
# Reinspected pallets were set to in_stock after being shipped.
# New workflow is that shipped pallets cant be reinspected.
#
class FixShippedPalletsBeingInStock < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    query = <<~SQL
      SELECT
        pallets.id,
        pallets.pallet_number
      FROM pallets
      JOIN govt_inspection_pallets gip ON pallets.id = gip.pallet_id
      WHERE shipped AND in_stock
    SQL
    ids = DB[query].select_map(:id)

    DB.transaction do
      puts "Updated pallets: #{ids.join(', ')} with (in_stock: false)"
      DB[:pallets].where(id: ids).update(in_stock: false)
      raise ArgumentError, 'Debug mode' if debug_mode
    end

    infodump = <<~STR
      Script: FixShippedPalletsBeingInStock

      What this script does:
      ----------------------
      Sets all shipped pallets in_stock to false

      Reason for this script:
      -----------------------
      Reinspected pallets were set to in_stock after being shipped.
      New workflow is that shipped pallets cant be reinspected.

      Results:
      --------
      Fixed shipped pallets where in_stock was true to false.
      pallet_ids: #{ids.join(', ')}
    STR

    log_infodump(:data_fix,
                 :shipped_palelts_in_stock,
                 :fix_shipped_pallets_being_in_stock,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Shipped pallets fixe')
    end
  end
end
