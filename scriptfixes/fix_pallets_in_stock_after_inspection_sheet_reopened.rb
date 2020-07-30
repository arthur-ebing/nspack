# frozen_string_literal: true

# What this script does:
# ----------------------
# Sets pallets to in_Stock to false when shipped, after reopen_inspection_sheet set in_stock to nil.
#
# Reason for this script:
# -----------------------
# Sitrusrand: shipped check was not inplace for inspection_sheets
#
class FixPalletsInStockAfterInspectionSheetReopened < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    ids = DB[:pallets].where(shipped: true, in_stock: nil).map(:id)

    if debug_mode
      puts "Debug: Updated pallets #{ids.join(', ')}"
    else
      DB.transaction do
        puts "Updated pallets #{ids.join(', ')}"
        DB[:pallets].where(id: ids).update(in_stock: false)
      end
    end

    infodump = <<~STR
      Script: FixPalletsInStockAfterInspectionSheetReopened

      What this script does:
      ----------------------
      Sets pallets to in_Stock to false when shipped, after reopen_inspection_sheet set in_stock to nil.

      Reason for this script:
      -----------------------
      Sitrusrand: shipped check was not inplace for inspection_sheets

      Results:
      --------
      Updated pallets

      pallets: #{ids.join(', ')}
    STR

    log_infodump(:data_fix,
                 :pallets_nil_instock,
                 :in_stock_to_false,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Updated Pallets')
    end
  end
end
