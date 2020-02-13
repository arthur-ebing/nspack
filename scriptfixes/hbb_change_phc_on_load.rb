# frozen_string_literal: true

# What this script does:
# ----------------------
# Takes pallets from load 413 and changes
# the PHC from L1463 to L7911.
#
# Reason for this script:
# -----------------------
# Badlands had the incorrect PHC code set in plant_resources.
# The PHC was fixed, but existing load 413 had the old PHC
# on its pallets.
# PPECB was not able to approve the addendum.
#
class HBBChangePhcOnLoad < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    new_phc = 'L7911'
    load_id = 413
    pallets = DB[:pallets].where(load_id: load_id).select_map(%i[id pallet_number phc])
    ids = pallets.map(&:first)

    return failed_response("There are no pallets with load_id #{load_id}") if ids.empty?

    puts "Changing phc to #{new_phc}"
    if debug_mode
      puts pallets.map { |p| "#{p[1]} - #{p[2]}" }.join("\n")
    else
      DB.transaction do
        DB[:pallets].where(id: ids).update(phc: new_phc)
        log_multiple_statuses(:pallets, ids, 'DATA FIX: PHC', comment: "changed to #{new_phc}", user_name: 'System')
      end
    end

    infodump = <<~STR
      Script: HBBChangePhcOnLoad

      What this script does:
      ----------------------
      Takes pallets from load 413 and changes
      the PHC from L1463 to L7911.

      Reason for this script:
      -----------------------
      Badlands had the incorrect PHC code set in plant_resources.
      The PHC was fixed, but existing load 413 had the old PHC
      on its pallets.
      PPECB was not able to approve the addendum.

      Results:
      --------
      Set PHC to #{new_phc} for pallets:

      pallet ids: #{ids.join(', ')}

      pallet numbers:
      #{pallets.map { |p| p[1] }.join("\n")}
    STR

    log_infodump(:data_fix,
                 :load_pallets,
                 :change_phc,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Updated pallets')
    end
  end
end
