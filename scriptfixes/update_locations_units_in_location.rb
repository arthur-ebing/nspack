# frozen_string_literal: true

# What this script does:
# ----------------------
# Adds the amount of bins and pallets whose location_id=location.id and sets that to location.units_in_location
#
# Reason for this script:
# -----------------------
# There are locations in the system that have pallets in them but are not included in units_in_location
#
class UpdateLocationsUnitsInLocation < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    query = <<~SQL
      select id, location_long_code, pallets_in_location, bins_in_location
      from (select l.id, l.location_long_code, count(s.pallet_number) as pallets_in_location, count(b.id) as bins_in_location
         from locations l
         left outer join pallets s on s.location_id=l.id
         left outer join rmt_bins b on b.location_id=l.id
         group by l.id, l.location_long_code) as location_units
      where pallets_in_location > 0 or bins_in_location > 0
    SQL
    locations_with_units = DB[query].all
    p "Locations with bins and pallets in them: #{locations_with_units.count}"
    text_data = []
    text_data << 'id,location_long_code,pallets_in_location,bins_in_location'
    locations_with_units.each do |l|
      unless debug_mode
        DB.transaction do
          upd = <<~SQL
            UPDATE locations
            SET units_in_location = ?
            WHERE id=?
          SQL
          DB[upd, l[:pallets_in_location] + l[:bins_in_location], l[:id]].update
        end
      end
      text_data << "#{l[:id]},#{l[:location_long_code]},#{l[:pallets_in_location]}, #{l[:bins_in_location]}"
    end

    infodump = <<~STR
      Script: UpdateLocationsUnitsInLocation

      What this script does:
      ----------------------
      Adds the amount of bins and pallets whose location_id=location.id and sets that to location.units_in_location

      Reason for this script:
      -----------------------
      There are locations in the system that have pallets in them but are not included in units_in_location

      Results:
      --------

      data: updated locations(#{locations_with_units.map { |l| l[:id] }.join(',')})

      text data:
      #{text_data.join("\n")}
    STR

    unless locations_with_units.empty?
      log_infodump(:data_fix,
                   :pallets_and_rmt_bins,
                   :update_locations_units_in_location,
                   infodump)
    end

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Out Of Sync Deliveries and Bins Fixed')
    end
  end
end
