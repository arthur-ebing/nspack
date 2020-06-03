# frozen_string_literal: true

# Script: FixRebinLocations
#
# What this script does:
# ----------------------
# 1. updates rebins.location_id
# 2. updates location_id for rebins that were created without a default location
#
# Reason for this script:
# -----------------------
# create_rebin did not set the rebin's location_id
#
class FixRebinLocations < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    query = <<~SQL
      select b.id, p.location_id as default_location_id
      from rmt_bins b
      join production_runs r on r.id=b.production_run_rebin_id
      JOIN plant_resources p on p.id=r.packhouse_resource_id
      where is_rebin is true and b.location_id is null
      order by b.id desc;
    SQL
    rebins = DB[query].all
    return failed_response('There are no rebins to fix') if rebins.empty?

    p "Records affected: #{rebins.count}"

    text_data = []
    DB.transaction do
      rebins.each do |rebin|
        text_data << "updated location_id : #{rebin[:id]} : #{rebin[:default_location_id]} "
        DB[:rmt_bins].where(id: rebin[:id]).update(location_id: rebin[:default_location_id])
      end
    end

    infodump = <<~STR
      Script: FixRebinLocations

      What this script does:
      ----------------------
      1. updates rebins.location_id
      2. updates location_id for rebins that were created without a default location

      Reason for this script:
      -----------------------
      create_rebin did not set the rebin's location_id

      Results:
      --------
      #{text_data.join("\n\n")}
    STR

    unless rebins.empty?
      log_infodump(:data_fix,
                   :location_id,
                   :update_rebins_location_id,
                   infodump)
    end

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Rebins location ids updated successfully')
    end
  end
end
