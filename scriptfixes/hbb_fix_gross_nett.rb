# frozen_string_literal: true

# require 'logger'
class HBBFixGrossNett < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    pallet_ids = DB[:pallets].exclude(nett_weight: nil).where(gross_weight: nil).order(:id).select_map(:id)
    p "Records affected: #{pallet_ids.count}"

    pallet_ids.each do |pallet_id|
      nett_weight = DB[:pallets].where(id: pallet_id).get(:nett_weight)

      attrs = { gross_weight: nett_weight }
      if debug_mode
        p "Updated pallet #{pallet_id}: #{attrs}"
      else
        DB.transaction do
          p "Updated pallet #{pallet_id}: #{attrs}"
          DB[:pallets].where(id: pallet_id).update(attrs)
        end
      end
    end

    log_infodump(:data_fix,
                 :badlands,
                 :set_gross_weight,
                 "Updated pallet gross_weight = nett_weight for pallet_ids:#{pallet_ids}")

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Bin weights set')
    end
  end
end
