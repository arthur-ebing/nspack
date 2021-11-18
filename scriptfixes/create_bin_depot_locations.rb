# frozen_string_literal: true

# What this script does:
# ----------------------
# Loops through all existing bin depots and creates corresponding locations
#
# Reason for this script:
# -----------------------
# This script creates locations for existing bin depots.
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb CreateBinDepotLocations
# Live  : RACK_ENV=production ruby scripts/base_script.rb CreateBinDepotLocations
# Dev   : ruby scripts/base_script.rb CreateBinDepotLocations
#
class CreateBinDepotLocations < BaseScript
  attr_reader :repo, :location_ids

  def run # rubocop:disable Metrics/AbcSize
    @repo = MasterfilesApp::DepotRepo.new
    bin_depots = DB[:depots].where(bin_depot: true).select_map(:depot_code)
    p "Records found: #{bin_depots.count}"

    @ar_log = []
    @location_ids = []
    if debug_mode
      bin_depots.each do |depot_code|
        @ar_log << "Would create location #{depot_code}"
      end
      puts @ar_log.join("\n")
      puts 'Done'
    else
      DB.transaction do
        bin_depots.each do |depot_code|
          location_id = get_location_id(depot_code)
          next unless location_id.nil_or_empty?

          @ar_log << "Creating location: #{depot_code}"
          location_id = create_bin_depot_location(depot_code, resolve_location_attrs)
          @location_ids << location_id
        end
        log_multiple_statuses(:locations, location_ids, 'CREATED BIN DEPOT LOCATION', user_name: 'System')
      end
    end

    infodump = <<~STR
      Script: CreateBinDepotLocations

      What this script does:
      ----------------------
      Loops through all existing bin depots and creates corresponding locations.

      Reason for this script:
      -----------------------
      This script creates locations for existing bin depots.

      Results:
      --------
      Created locations:

      #{@ar_log.join("\n")}
    STR

    log_infodump(:data_fix,
                 :bin_depots,
                 :create_bin_depot_locations,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Created bin depot locations')
    end
  end

  private

  def get_location_id(depot_code)
    DB[:locations].where(location_long_code: depot_code).get(:id)
  end

  def resolve_location_attrs
    { primary_storage_type_id: @repo.get_id(:location_storage_types, storage_type_code: AppConst::STORAGE_TYPE_BIN_ASSET.to_s),
      location_type_id: @repo.get_id(:location_types, location_type_code: AppConst::DEPOT_DESTINATION_TYPE.to_s),
      primary_assignment_id: @repo.get_id(:location_assignments, assignment_code: AppConst::EMPTY_BIN_STORAGE.to_s) }
  end

  def create_bin_depot_location(depot_code, location_attrs)
    attrs = location_attrs.merge({ location_long_code: depot_code,
                                   location_description: depot_code,
                                   location_short_code: depot_code })
    DB[:locations].insert(attrs)
  end
end
