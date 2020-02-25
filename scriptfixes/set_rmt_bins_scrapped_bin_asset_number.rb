# frozen_string_literal: true

# What this script does:
# ----------------------
# Finds scrapped bin records and sets scrapped_bin_asset_number to the bin_asset_number value and bin_asset_number to null.
#
# Reason for this script:
# -----------------------
# Updated the reworks - scrap bins to update scrapped_bin_asset_number and bin_asset_number. Thus the need to update existing scrapped bins data.
#
class SetRmtBinsScrappedBinAssetNumber < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    rmt_bin_ids = DB[:rmt_bins].exclude(bin_asset_number: nil).where(scrapped: true).select_map(:id)
    return failed_response('There are no scrapped rmt_bins') if rmt_bin_ids.empty?

    p "Records affected: #{rmt_bin_ids.count}"

    text_data = []
    rmt_bin_ids.each do |rmt_bin_id|
      bin_asset_number = DB[:rmt_bins].where(id: rmt_bin_id).get(:bin_asset_number)
      text_data << "updated Bin #{rmt_bin_id}: bin_asset_number from #{bin_asset_number} to null and scrapped_bin_asset_number from null to #{bin_asset_number}"
      attrs = { bin_asset_number: nil,
                scrapped_bin_asset_number: bin_asset_number }
      if debug_mode
        p "Updated rmt_bin #{rmt_bin_id}: #{attrs}"
      else
        DB.transaction do
          p "Updated rmt_bin #{rmt_bin_id}: #{attrs}"
          DB[:rmt_bins].where(id: rmt_bin_id).update(attrs)
        end
      end
    end

    infodump = <<~STR
      Script: SetRmtBinsScrappedBinAssetNumber

      What this script does:
      ----------------------
      Finds scrapped bin records and sets scrapped_bin_asset_number to the bin_asset_number value and bin_asset_number to null.

      Reason for this script:
      -----------------------
      Updated the reworks - scrap bins to update scrapped_bin_asset_number and bin_asset_number. Thus the need to update existing scrapped bins data.

      Results:
      --------

      data: Updated bins(#{rmt_bin_ids.join(',')})

      text data:
      #{text_data.join("\n\n")}
    STR

    log_infodump(:data_fix,
                 :rmt_bins,
                 :set_rmt_bins_scrapped_bin_asset_number,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('rmt_bins scrapped_bin_asset_number set')
    end
  end
end
