# frozen_string_literal: true

# What this script does:
# ----------------------
# updates scrapped_rmt_delivery_id to rmt_delivery_id and mt_delivery_id to null for all scrapped rmt_bins
#
# Reason for this script:
# -----------------------
# added a new field scrapped_rmt_delivery_id updated when rmt_bins are scrapped
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb UpdateScrappedRmtBins
# Live  : RACK_ENV=production ruby scripts/base_script.rb UpdateScrappedRmtBins
# Dev   : ruby scripts/base_script.rb UpdateScrappedRmtBins
#
class UpdateScrappedRmtBins < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    rmt_bin_ids = DB[:rmt_bins].exclude(rmt_delivery_id: nil).where(scrapped: true).select_map(:id)
    return failed_response('There are no scrapped rmt_bins to update') if rmt_bin_ids.empty?

    p "Records affected: #{rmt_bin_ids.count}"
    text_data = []
    rmt_bin_ids.each do |rmt_bin_id|
      rmt_delivery_id = DB[:rmt_bins].where(id: rmt_bin_id).get(:rmt_delivery_id)
      text_data << "updated Bin #{rmt_bin_id}: rmt_delivery_id from #{rmt_delivery_id} to null and scrapped_rmt_delivery_id from null to #{rmt_delivery_id}"
      attrs = { rmt_delivery_id: nil,
                scrapped_rmt_delivery_id: rmt_delivery_id }
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
      Script: UpdateScrappedRmtBins

      What this script does:
      ----------------------
      updates scrapped_rmt_delivery_id to rmt_delivery_id and mt_delivery_id to null for all scrapped rmt_bins

      Reason for this script:
      -----------------------
      added a new field scrapped_rmt_delivery_id updated when rmt_bins are scrapped

      Results:
      --------

      data: Updated bins(#{rmt_bin_ids.join(',')})

      text data:
      #{text_data.join("\n\n")}
    STR

    log_infodump(:data_fix,
                 :rmt_bins,
                 :set_scrapped_rmt_delivery_id,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Something was done')
    end
  end
end
