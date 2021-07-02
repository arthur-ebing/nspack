# frozen_string_literal: true

# What this script does:
# ----------------------
# Loops through repacked pallets and resets the last_govt_inspection_pallet_id
#
# Reason for this script:
# -----------------------
# Repacking a pallet should reset the last_govt_inspection_pallet_id
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb ResetPalletLastGovtInspectionPalletId
# Live  : RACK_ENV=production ruby scripts/base_script.rb ResetPalletLastGovtInspectionPalletId
# Dev   : ruby scripts/base_script.rb ResetPalletLastGovtInspectionPalletId
#
class ResetPalletLastGovtInspectionPalletId < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    repacked_pallet_ids = DB[:pallets]
                          .exclude(last_govt_inspection_pallet_id: nil)
                          .where(:repacked)
                          .where(inspected: false)
                          .select_map(:id)
    return failed_response('There are no repacked pallets to update') if repacked_pallet_ids.empty?

    p "Records affected: #{repacked_pallet_ids.count}"

    if debug_mode
      p "Updated last_govt_inspection_pallet_id to null for pallets with ids: #{repacked_pallet_ids.join(',')}"
    else
      DB.transaction do
        p "Updated last_govt_inspection_pallet_id to null for pallets with ids: #{repacked_pallet_ids.join(',')}"
        DB[:pallets].where(id: repacked_pallet_ids).update({ last_govt_inspection_pallet_id: nil })
      end
    end

    infodump = <<~STR
      Script: ResetPalletLastGovtInspectionPalletId

      What this script does:
      ----------------------
      Loops through repacked pallets and resets the last_govt_inspection_pallet_id

      Reason for this script:
      -----------------------
      Repacking a pallet should reset the last_govt_inspection_pallet_id

      Results:
      --------
      Updated #{repacked_pallet_ids.count} repacked pallets.

    STR

    unless repacked_pallet_ids.nil_or_empty?
      log_infodump(:data_fix,
                   :repacked_pallets,
                   :update_last_govt_inspection_pallet_id,
                   infodump)
    end

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('last_govt_inspection_pallet_id for repacked pallets updated successfully')
    end
  end
end
