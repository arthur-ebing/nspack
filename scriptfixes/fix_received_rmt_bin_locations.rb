# frozen_string_literal: true

# require 'logger'
class FixReceivedRmtBinLocations < BaseScript
  def run
    ids = DB[:rmt_bins].where(location_id: nil).exclude(bin_received_date_time: nil).select_map(:id)
    location_id = AppConst::CR_RMT.default_delivery_location
    p "Records affected: #{ids.count} moved to location_id #{location_id}"
    DB.transaction do
      DB[:rmt_bins].where(id: ids).update(location_id: location_id) unless debug_mode
    end

    infodump = <<~STR
      Script: FixReceivedRmtBinLocations

      What this script does:
      ----------------------
      Updates the location_id of all received RMT Bins where location id is null

      Reason for this script:
      -----------------------
      Data fix

      Results:
      --------

      "Records affected: rmt_bins: #{ids} moved to location_id #{location_id}"
    STR

    log_infodump(:data_fix,
                 :rmt_bins,
                 :update_received_bins_location,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('success')
    end
  end
end
