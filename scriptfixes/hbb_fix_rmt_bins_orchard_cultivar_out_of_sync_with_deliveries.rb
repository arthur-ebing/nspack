# frozen_string_literal: true

# What this script does:
# ----------------------
# Takes bins on a delivery that have a different orchard/cultivar, clones/create a new delivery with orchard/cultivar that match those of the bins and assign bins to new_delivery
#
# Reason for this script:
# -----------------------
# There are bins in the system that have a different orchard/cultivar to the delivery
#
class HbbFixRmtBinsOrchardCultivarOutOfSyncWithDeliveries < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    query = <<~SQL
      SELECT d.id as delivery_id, b.id as bin_id, d.farm_id, d.puc_id, d.date_picked, d.date_delivered, d.delivery_tipped, d.tipping_complete_date_time, d.orchard_id as del_orchard_id , b.orchard_id as bin_orchard_id, d.cultivar_id as del_cultivar_id, b.cultivar_id as bin_cultivar_id
      FROM rmt_deliveries d
      JOIN rmt_bins b on b.rmt_delivery_id = d.id
      WHERE (d.orchard_id <> b.orchard_id) or (d.cultivar_id <> b.cultivar_id)
    SQL
    rmt_delivery_bins = DB[query].all
    p "Bin Records affected: #{rmt_delivery_bins.count}"

    rmt_delivery_bins.group_by { |h| h[:delivery_id] }.each do |_k, v|
      if debug_mode
        v.group_by { |h| "#{h[:bin_orchard_id]},#{h[:bin_cultivar_id]}" }.each do |_key, val|
          season_id = rmt_delivery_season(val[0][:bin_cultivar_id], val[0][:date_delivered])
          p "Delivery To Be Created: #{{ tipping_complete_date_time: val[0][:tipping_complete_date_time], delivery_tipped: val[0][:delivery_tipped], date_delivered: val[0][:date_delivered], season_id: season_id, farm_id: val[0][:farm_id], puc_id: val[0][:puc_id], orchard_id: val[0][:bin_orchard_id], cultivar_id: val[0][:bin_cultivar_id], date_picked: val[0][:date_picked], current: false }}"
        end
      else
        v.group_by { |h| "#{h[:bin_orchard_id]},#{h[:bin_cultivar_id]}" }.each do |_key, val|
          DB.transaction do
            season_id = rmt_delivery_season(val[0][:bin_cultivar_id], val[0][:date_delivered])
            rmt_delivery_id = DB[:rmt_deliveries].insert(tipping_complete_date_time: val[0][:tipping_complete_date_time], delivery_tipped: val[0][:delivery_tipped], date_delivered: val[0][:date_delivered], season_id: season_id, farm_id: val[0][:farm_id], puc_id: val[0][:puc_id], orchard_id: val[0][:bin_orchard_id], cultivar_id: val[0][:bin_cultivar_id], date_picked: val[0][:date_picked], current: false)
            DB[:rmt_bins].where(id: val.map { |b| b[:bin_id] }).update(rmt_delivery_id: rmt_delivery_id)
          end
        end
      end
    end


    infodump = <<~STR
      Script: HbbFixRmtBinsOrchardCultivarOutOfSyncWithDeliveries

      What this script does:
      ----------------------
      Takes bins on a delivery that have a different orchard/cultivar, clones/create a new delivery with orchard/cultivar that match those of the bins and assign bins to new_delivery

      Reason for this script:
      -----------------------
      There are bins in the system that have a different orchard/cultivar to the delivery

      Results:
      --------
      Updated something

      data: bins.delivery_id = new_delivery.id

      text data:
      #{rmt_delivery_bins.map { |b| b[:bin_id] }.join("\n")}
    STR

    unless rmt_delivery_bins.map { |b| b[:bin_id] }.empty?
      log_infodump(:data_fix,
                   :badlands,
                   :hbb_fix_rmt_bins_orchard_cultivar_out_of_sync_with_deliveries,
                   infodump)
    end

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Out Of Sync Deliveries and Bins Fixed')
    end
  end
  private

  def rmt_delivery_season(cultivar_id, date_delivered)
    hash = DB["SELECT s.*
         FROM seasons s
          JOIN cultivars c on c.commodity_id=s.commodity_id
         WHERE c.id = #{cultivar_id} and '#{date_delivered}' between start_date and end_date"].first
    return nil if hash.nil?

    hash[:id]
  end
end
