# frozen_string_literal: true

# require 'logger'
class HBBFixRmtBinsTippedAssetNumber < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    query = <<~SQL
      SELECT DISTINCT la.row_data_id AS rmt_bin_id, la.row_data -> 'bin_asset_number' AS bin_asset_number
      FROM audit.logged_actions la
      JOIN public.rmt_bins ON public.rmt_bins.id = la.row_data_id AND public.rmt_bins.tipped_asset_number = la.row_data_id::text
      WHERE schema_name = 'public' AND table_name = 'rmt_bins' AND action = 'U' AND changed_fields->'tipped_manually' = 't'
    SQL
    rmt_bin_ids = DB[query].all
    p "Records affected: #{rmt_bin_ids.count}"

    rmt_bin_ids.each do |rmt_bin|
      rmt_bin_id = rmt_bin[:rmt_bin_id]
      attrs = { tipped_asset_number: rmt_bin[:bin_asset_number] }
      if debug_mode
        p "Updated rmt_bin #{rmt_bin_id}: #{attrs}"
      else
        DB.transaction do
          p "Updated rmt_bin #{rmt_bin_id}: #{attrs}"
          DB[:rmt_bins].where(id: rmt_bin_id).update(attrs)
        end
      end
    end

    log_infodump(:data_fix,
                 :badlands,
                 :fix_rmt_bins_tipped_asset_number,
                 "Updated tipped_asset number = asset_number for rmt_bin_ids:#{rmt_bin_ids}")

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('rmt_bins tipped_asset_number set')
    end
  end
end
