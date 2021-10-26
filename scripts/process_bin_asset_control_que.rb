# frozen_string_literal: true

# What this script does:
# ----------------------
# Calls a RawMaterialsApp::BinAssetControlProcessor service that loops through and processes bin_asset_transactions_queue records.
#
# Reason for this script:
# -----------------------
# This allows for the track and trace of full and/ or empty bins bin assets.
# Script is run on the hour.
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb ProcessBinAssetControlQue
# Live  : RACK_ENV=production ruby scripts/base_script.rb ProcessBinAssetControlQue
# Dev   : ruby scripts/base_script.rb ProcessBinAssetControlQue
#
class ProcessBinAssetControlQue < BaseScript
  def run
    DB.transaction do
      puts 'RUNNING'

      if debug_mode
        puts 'Bin Asset Control:'
      else
        puts 'Processing Bin Asset Control:'
        RawMaterialsApp::BinAssetControlProcessor.call
      end

      infodump
      success_response('Bin Asset Control Que processed successfully')
    end
  rescue StandardError => e
    failed_response(e.message)
  end

  def infodump
    infodump = <<~STR
      Script: ProcessBinAssetControlQue

      What this script does:
      -----------------------
      Calls RawMaterialsApp::BinAssetControlProcessor service that loops through and processes bin_asset_transactions_queue records.

      Reason for this script:
      -----------------------
      This allows for the track and trace of full and/ or empty bins bin assets.
      Script is run on the hour.

      Results:
      --------
      Bin Asset Control output
    STR

    log_infodump(:data_import,
                 :process_bin_asset_control_events,
                 :bin_asset_control,
                 infodump)
  end
end
