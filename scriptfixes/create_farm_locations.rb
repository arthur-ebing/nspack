# frozen_string_literal: true

# What this script does:
# ----------------------
# Loops through all existing farms and creates corresponding locations
# Updates the farms location_id.
#
# Reason for this script:
# -----------------------
# This script creates locations and updates location_id for existing farms.
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb CreateFarmLocations
# Live  : RACK_ENV=production ruby scripts/base_script.rb CreateFarmLocations
# Dev   : ruby scripts/base_script.rb CreateFarmLocations
#
class CreateFarmLocations < BaseScript
  attr_reader :repo, :location_ids

  def run # rubocop:disable Metrics/AbcSize
    @repo = MasterfilesApp::FarmRepo.new
    farms = DB[:farms].select_map(%i[id farm_code])
    farm_ids = farms.map(&:first)

    p "Records affected: #{farm_ids.count}"

    @ar_log = []
    @location_ids = []
    if debug_mode
      farms.each do |_id, farm_code|
        @ar_log << "Would create location #{farm_code}"
      end
      puts @ar_log.join("\n")
      puts 'Done'
    else
      DB.transaction do
        farms.each do |id, farm_code|
          location_id = DB[:farms].where(id: id).get(:location_id)
          next unless location_id.nil_or_empty?

          @ar_log << "Creating location: #{farm_code}"
          create_farm_location(id, farm_code, resolve_location_attrs)
        end
        log_multiple_statuses(:locations, location_ids, 'CREATED FARM LOCATION', user_name: 'System')
        log_multiple_statuses(:farms, farm_ids, 'UPDATED LOCATION ID', user_name: 'System')
      end
    end

    infodump = <<~STR
      Script: CreateFarmLocations

      What this script does:
      ----------------------
      Loops through all existing farms and creates corresponding locations and update the farm's location_id.

      Reason for this script:
      -----------------------
      This script creates locations and updates location_id for existing farms.

      Results:
      --------
      Created locations:

      #{@ar_log.join("\n")}
    STR

    log_infodump(:data_fix,
                 :farms,
                 :create_farm_locations,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Created farm locations')
    end
  end

  private

  def resolve_location_attrs
    { primary_storage_type_id: @repo.get_id(:location_storage_types, storage_type_code: AppConst::STORAGE_TYPE_BIN_ASSET.to_s),
      location_type_id: @repo.get_id(:location_types, location_type_code: AppConst::LOCATION_TYPES_FARM.to_s),
      primary_assignment_id: @repo.get_id(:location_assignments, assignment_code: AppConst::EMPTY_BIN_STORAGE.to_s) }
  end

  def create_farm_location(farm_id, farm_code, location_attrs)
    attrs = location_attrs.merge({ location_long_code: farm_code,
                                   location_description: farm_code,
                                   location_short_code: farm_code })
    location_id = get_location_id(attrs)

    DB[:farms].where(id: farm_id).update(location_id: location_id)
    @ar_log << "Updated farm location_id to #{location_id}"
    @location_ids << location_id
  end

  def get_location_id(attrs)
    location_id = DB[:locations].where(location_long_code: attrs[:location_long_code]).get(:id)
    return location_id unless location_id.nil?

    DB[:locations].insert(attrs)
  end
end
