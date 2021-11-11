# frozen_string_literal: true

# What this script does:
# ----------------------
# The script copies attributes from run.legacy_data over to bin.legacy_data

# Reason for this script:
# -----------------------
# Rebins were created with null legacy_data. This scripts fixes that.

# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb FixRebinLegacyNullData
# Live  : RACK_ENV=production ruby scripts/base_script.rb FixRebinLegacyNullData
# Dev   : ruby scripts/base_script.rb FixRebinLegacyNullData

class FixRebinLegacyNullData < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    repo = RawMaterialsApp::RmtDeliveryRepo.new
    rebins = DB[:rmt_bins]
             .select(:id, :production_run_rebin_id)
             .where(Sequel.lit('legacy_data is null and production_run_rebin_id is not null'))
             .all

    DB.transaction do
      unless debug_mode
        rebins.group_by { |h| h[:production_run_rebin_id] }.each do |k, v|
          legacy_data = repo.get_value(:production_runs, :legacy_data, id: k)
          bin_ids = v.map { |b| b[:id] }
          rebin_legacy_data = { colour: legacy_data['treatment_code'],
                                pc_code: legacy_data['pc_code'],
                                cold_store_type: legacy_data['cold_store_type'],
                                track_slms_indicator_1_code: legacy_data['track_indicator_code'],
                                ripe_point_code: legacy_data['ripe_point_code'] }
          repo.update_rmt_bin(bin_ids, legacy_data: rebin_legacy_data)
        end
      end
    end

    info_dump(rebins.length)
    success_response('Completed update.')
  rescue StandardError => e
    ErrorMailer.send_exception_email(e, subject: 'FixRebinLegacyNullData failure')
    failed_response(e.message)
  end

  private

  def info_dump(updates)
    infodump = <<~STR
      Script: FixRebinLegacyNullData

      Reason for this script:
      -----------------------
      Rebins were created with null legacy_data. This scripts fixes that.

      Results:
      --------
      No of rebins updated: #{updates}
    STR
    log_infodump(:data_fix,
                 :rebins,
                 :set_legacy_data,
                 infodump)
  end
end
