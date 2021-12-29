# frozen_string_literal: true

# What this script does:
# ----------------------
# Works through non-scrapped, non-allocated sequences cecreated in the recent number of days and rebuilds the FG code using inputs from the sequences instead of the product setup.
#
# Reason for this script:
# -----------------------
# Sequences can be created and have the FG code lookup fail, but later changes to the sequence data means that the lookup would succeed because the attributes of the sequence have changed to enable a match.
#
# To run: (nnn represents the number of days back to go to select pallets)
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb UpdateExtendedFGCodes nnn
# Live  : RACK_ENV=production ruby scripts/base_script.rb UpdateExtendedFGCodes nnn
# Dev   : ruby scripts/base_script.rb UpdateExtendedFGCodes nnn
#
class UpdateExtendedFGCodes < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    raise ArgumentError, 'Please supply the number of days' if args.first.nil?

    no_days = args.first.to_i
    from_date = Date.today - no_days - 1

    query = <<~SQL
      SELECT DISTINCT pallet_id
      FROM pallet_sequences
      JOIN pallets ON pallets.id = pallet_sequences.pallet_id
      WHERE pallet_sequences.updated_at > ?
        -- AND NOT pallets.allocated
    SQL
    pallet_ids = DB[query, from_date].select_map(:pallet_id)

    sets = []
    if debug_mode
      puts "Update extended FG codes #{pallet_ids.length} pallets found to be checked"
      pallet_ids.each_slice(50) do |set|
        sets << set
        puts "Enqueue FinishedGoodsApp::Job::CalculateExtendedFgCodesFromSeqs with #{set.inspect}"
      end
    else
      pallet_ids.each_slice(50) do |set|
        sets << set
        puts "Enqueue FinishedGoodsApp::Job::CalculateExtendedFgCodesFromSeqs with #{set.inspect}"
        FinishedGoodsApp::Job::CalculateExtendedFgCodesFromSeqs.enqueue(set)
      end
    end

    infodump = <<~STR
      Script: UpdateExtendedFGCodes

      What this script does:
      ----------------------
      Works through non-scrapped, non-allocated sequences cecreated in the recent number of days and rebuilds the FG code using inputs from the sequences instead of the product setup.

      Reason for this script:
      -----------------------
      Sequences can be created and have the FG code lookup fail, but later changes to the sequence data means that the lookup would succeed because the attributes of the sequence have changed to enable a match.

      Results:
      --------
      Pallet ids for update - job enqued for each set of 50 ids:
      #{sets.map(&:inspect).join("\n")}
    STR

    log_infodump(:data_fix,
                 :pallet_seqs,
                 :update_fg_code,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Updates enqueued')
    end
  end
end
