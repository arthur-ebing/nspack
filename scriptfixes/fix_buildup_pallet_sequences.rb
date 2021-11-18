# frozen_string_literal: true

# What this script does:
# ----------------------
# Removes pallet sequences where carton_quantity is zero
# Scraps the pallet if the sequence was the last one on the pallet
#
# Reason for this script:
# -----------------------
# These sequences where done before Buildup pallet change to remove a sequence when carton_quantity becomes zero
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb FixBuildupPalletSequences
# Live  : RACK_ENV=production ruby scripts/base_script.rb FixBuildupPalletSequences
# Dev   : ruby scripts/base_script.rb FixBuildupPalletSequences
#
class FixBuildupPalletSequences < BaseScript
  attr_reader :repo, :sequence_ids

  def run # rubocop:disable Metrics/AbcSize
    @repo = ProductionApp::ReworksRepo.new
    @sequence_ids = DB[:pallet_sequences]
                    .where(carton_quantity: 0)
                    .exclude(pallet_id: nil)
                    .select_map(%i[id pallet_id])
    return failed_response('There are no pallet sequences to fix') if sequence_ids.nil_or_empty?

    p "#{sequence_ids.count} pallet sequences records to fix."
    @text_data = []

    DB.transaction do
      sequence_ids.each do |sequence_id, pallet_id|
        if debug_mode
          p "removed pallet sequence : #{sequence_id}\n"
        else
          if cannot_remove_sequence(pallet_id)
            status = 'PALLET SCRAPPED BY BUILDUP PALLET SEQUENCE FIX'
            attrs = { scrapped_at: Time.now, pallet_id: nil, scrapped_from_pallet_id: pallet_id, exit_ref: AppConst::PALLET_EXIT_REF_SCRAPPED }
            str = "scrapped pallet : #{pallet_id}\n"
            DB[:pallets].where(id: pallet_id).update({ scrapped: true, scrapped_at: Time.now, exit_ref: AppConst::PALLET_EXIT_REF_SCRAPPED })
          else
            status = 'SEQUENCE REMOVED BY BUILDUP PALLET SEQUENCE FIX'
            attrs = { removed_from_pallet: true, removed_from_pallet_at: Time.now, pallet_id: nil, removed_from_pallet_id: pallet_id, exit_ref: AppConst::SEQ_REMOVED_BY_CTN_TRANSFER }
            str = "removed pallet sequence : #{sequence_id} attrs: #{attrs}\n"
          end
          @text_data << str
          DB[:pallet_sequences].where(id: sequence_id).update(attrs)
          log_status(:pallets, pallet_id, status, user_name: 'System')
          log_status(:pallet_sequences, sequence_id, status, user_name: 'System')
        end
      end
    end

    infodump
    success_response('Buildup pallet sequences fixed successfully')
  end

  def cannot_remove_sequence(pallet_id)
    repo.unscrapped_sequences_count(pallet_id) <= 1
  end

  def infodump
    infodump = <<~STR
      Script: FixBuildupPalletSequences

      What this script does:
      ----------------------
      Removes pallet sequences where carton_quantity is zero
      Scraps the pallet if the sequence was the last one on the pallet

      Reason for this script:
      -----------------------
      These sequences where done before Buildup pallet change to remove a sequence when carton_quantity becomes zero

      Results:
      --------
      data: Affected pallet_sequences(#{sequence_ids.join(',')})

      text data:
      #{@text_data.join("\n\n")}

    STR
    log_infodump(:data_fix,
                 :pallet_sequences_buildup_fix,
                 :fix_buildup_pallet_sequences,
                 infodump)
  end
end
