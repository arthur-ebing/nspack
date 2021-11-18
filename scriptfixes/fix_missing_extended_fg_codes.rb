# frozen_string_literal: true

# What this script does:
# ----------------------
# Works through non-scrapped sequences with null extended fg codes and rebuilds the FG code using inputs from the sequences instead of the product setup.
#
# Reason for this script:
# -----------------------
# Sequences can be created and have the FG code lookup fail, but later changes to the sequence data means that the lookup would succeed because the attributes of the sequence have changed to enable a match.
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb FixMissingExtendedFGCodes
# Live  : RACK_ENV=production ruby scripts/base_script.rb FixMissingExtendedFGCodes
# Dev   : ruby scripts/base_script.rb FixMissingExtendedFGCodes
#
class FixMissingExtendedFGCodes < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    query = <<~SQL
      SELECT DISTINCT pallet_id
      FROM pallet_sequences
      WHERE legacy_data ->> 'extended_fg_code' IS NULL
        AND pallet_id IS NOT NULL
    SQL
    pallet_ids = DB[query].select_map(:pallet_id)

    sets = []
    if debug_mode
      puts 'Calculate extended FG codes'
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
      Script: FixMissingExtendedFGCodes

      What this script does:
      ----------------------
      Works through non-scrapped sequences with null extended fg codes and rebuilds the FG code using inputs from the sequences instead of the product setup.

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
      success_response('Something was done')
    end
  end
end
