# frozen_string_literal: true

# require 'logger'
class UpdateTippedBinsLocation < LuksBaseScript
  def run # rubocop:disable Metrics/AbcSize
    return failed_response('Please pass DEFAULT_DELIVERY_LOCATION as a parameter') unless args[0]

    query = <<~SQL
      select b.id, r.packhouse_resource_id, b.production_run_tipped_id, p.location_id as location_to_id
      from rmt_bins b
      join locations l on l.id=b.location_id
      join production_runs r on r.id=b.production_run_tipped_id
      join plant_resources p on p.id=r.packhouse_resource_id
      where bin_tipped is true and l.location_long_code = ?
    SQL
    tipped_rmt_bins = DB[query, args[0]].all
    p "Records affected: #{tipped_rmt_bins.count}"

    text_data = []
    tipped_rmt_bins.group_by { |t| t[:location_to_id] }.each do |k, v|
      text_data << "data: updated bins(#{v.map { |b| b[:id] }.join(',')})"
      text_data << "text data:\n new_location_id = #{k}\n\n\n"

      DB[:rmt_bins].where(id: v.map { |b| b[:id] }).update(location_id: k) unless debug_mode
    end

    infodump = <<~STR
      Script: UpdateTippedBinsLocation

      What this script does:
      ----------------------
      Updates the location_id of all tipped_bins where MoveStock was not done

      Reason for this script:
      -----------------------
      MoveStock was not done when bins were tipped

      Results:
      --------

      #{text_data.join("\n\n")}
    STR

    unless tipped_rmt_bins.empty?
      log_infodump(:data_fix,
                   :rmt_bins,
                   :update_tipped_bins_location,
                   infodump)
    end

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('rmt_bins tipped_asset_number set')
    end
  end
end
