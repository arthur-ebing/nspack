# frozen_string_literal: true

# What this script does:
# ----------------------
# Sets all shipped pallets in_stock to false
#
# Reason for this script:
# -----------------------
# Local pallets were set to in_stock after being shipped.
# New workflow is that shipped local pallets cant be set to in_stock.
#
class FixShippedLocalPalletsBeingInStock < BaseScript
  def run
    query = <<~SQL
      SELECT
          id,
          pallet_number,
          audit.previous_stock_created_at AS stock_created_at
      FROM pallets
      JOIN (  SELECT
                  row_data_id,
                  row_data -> 'stock_created_at' AS previous_stock_created_at
              FROM audit.logged_actions
              WHERE table_name = 'pallets'
                AND changed_fields -> 'stock_created_at' IS NOT NULL
                AND row_data -> 'shipped' = 't') audit ON pallets.id = audit.row_data_id
      WHERE shipped
        AND in_stock
    SQL
    array = DB[query].select_map(%i[id pallet_number stock_created_at])

    DB.transaction do
      array.each do |id, pallet_number, stock_created_at|
        puts "Updated pallet: #{pallet_number} with (in_stock: false, stock_created_at:#{stock_created_at})"
        DB[:pallets].where(id: id).update(in_stock: false, stock_created_at: stock_created_at)
      end
      raise ArgumentError, 'Debug mode' if debug_mode
    end

    infodump = <<~STR
      Script: FixShippedPalletsBeingInStock

      What this script does:
      ----------------------
      Sets all shipped pallets in_stock to false

      Reason for this script:
      -----------------------
      Local pallets were set to in_stock after being shipped.
      New workflow is that shipped local pallets cant be set to in_stock.

      Results:
      --------
      Fixed shipped pallets where in_stock was true to false.
      pallets: #{array}
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
