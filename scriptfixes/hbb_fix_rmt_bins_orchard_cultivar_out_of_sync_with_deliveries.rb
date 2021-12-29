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
      WHERE (d.orchard_id <> b.orchard_id OR d.cultivar_id <> b.cultivar_id)
      AND EXISTS(SELECT id FROM rmt_bins WHERE rmt_delivery_id = d.id
          AND (COALESCE(rmt_bins.orchard_id, 0) = COALESCE(d.orchard_id, 0)
          AND  COALESCE(rmt_bins.cultivar_id, 0) = COALESCE(d.cultivar_id, 0)))
    SQL
    rmt_delivery_bins = DB[query].all
    p "Bin Records affected: #{rmt_delivery_bins.count}"

    text_data = []
    rmt_delivery_bins.group_by { |h| h[:delivery_id] }.each do |_k, v|
      if debug_mode
        v.group_by { |h| "#{h[:bin_orchard_id]},#{h[:bin_cultivar_id]}" }.each do |_key, val|
          delivery = val.first
          text_data << "Bins(#{val.map { |b| b[:bin_id] }.join(',')}) : delivery_id from #{delivery[:delivery_id]} to new_rmt_delivery_id"
          season_id = rmt_delivery_season(delivery[:bin_cultivar_id], delivery[:date_delivered])
          p "Delivery To Be Created: #{{ tipping_complete_date_time: delivery[:tipping_complete_date_time],
                                         delivery_tipped: delivery[:delivery_tipped],
                                         date_delivered: delivery[:date_delivered].to_s,
                                         season_id: season_id,
                                         farm_id: delivery[:farm_id],
                                         puc_id: delivery[:puc_id],
                                         orchard_id: delivery[:bin_orchard_id],
                                         cultivar_id: delivery[:bin_cultivar_id],
                                         date_picked: delivery[:date_picked].to_s,
                                         current: false }}"
        end
      else
        v.group_by { |h| "#{h[:bin_orchard_id]},#{h[:bin_cultivar_id]}" }.each do |_key, val|
          delivery = val.first
          DB.transaction do
            season_id = rmt_delivery_season(delivery[:bin_cultivar_id], delivery[:date_delivered])
            rmt_delivery_id = DB[:rmt_deliveries].insert(tipping_complete_date_time: delivery[:tipping_complete_date_time],
                                                         delivery_tipped: delivery[:delivery_tipped],
                                                         date_delivered: delivery[:date_delivered],
                                                         season_id: season_id,
                                                         farm_id: delivery[:farm_id],
                                                         puc_id: delivery[:puc_id],
                                                         orchard_id: delivery[:bin_orchard_id],
                                                         cultivar_id: delivery[:bin_cultivar_id],
                                                         date_picked: delivery[:date_picked].to_s,
                                                         current: false)
            DB[:rmt_bins].where(id: val.map { |b| b[:bin_id] }).update(rmt_delivery_id: rmt_delivery_id)
            log_status(:rmt_deliveries, delivery[:delivery_id], 'DATA FIX: SPLIT UP DELIVERY', comment: "became #{rmt_delivery_id}", user_name: 'System')
            log_status(:rmt_deliveries, rmt_delivery_id, 'CREATE FROM SPLIT DELIVERY', comment: "created from #{delivery[:delivery_id]}", user_name: 'System')
            log_multiple_statuses(:rmt_bins, val.map { |b| b[:bin_id] }, 'DATA FIX: SPLIT DELIVERY', comment: "changed from #{delivery[:delivery_id]}", user_name: 'System')
            text_data << "Bins(#{val.map { |b| b[:bin_id] }.join(',')}) : delivery_id from #{delivery[:delivery_id]} to #{rmt_delivery_id}"
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

      data: updated bins(#{rmt_delivery_bins.map { |b| b[:bin_id] }.join(',')})

      text data:
      #{text_data.join("\n\n")}
    STR

    unless rmt_delivery_bins.map { |b| b[:bin_id] }.empty?
      log_infodump(:data_fix,
                   :rmt_bins,
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
    # DB["SELECT s.id
    #     FROM seasons s
    #     JOIN cultivars c on c.commodity_id=s.commodity_id
    #     WHERE c.id = #{cultivar_id} and ('#{date_delivered}' >= start_date and '#{date_delivered}' <= end_date)"].get(:id)
    DB[:seasons]
      .join(:cultivars, commodity_id: :commodity_id)
      .where(Sequel[:cultivars][:id] => cultivar_id)
      .where { start_date <= date_delivered }
      .where { end_date >= date_delivered }
      .get(Sequel[:seasons][:id])
  end
end
