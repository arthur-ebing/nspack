# frozen_string_literal: true

# What this script does:
# ----------------------
# The script reads the bin_integration_queue, assigns a job number and starts a background job.
# The background job reads all records in the queue with job number matching input parameter.
# Apply changes to rmt_bins table.
# Write errors to table if any.

# Reason for this script:
# -----------------------
# Bin integration service: from old system to new system
# Nspack will handle bins from the point where bins are added to a rmt tripsheet
# (in order to take them from the delivery to the tripsheet's destination)
# i.e. deliveries will be created in the old system.
# At this point bins will have to exist i.e. bins need to have been fetched from old system.

# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb ExecuteBinIntegrationQueue
# Live  : RACK_ENV=production ruby scripts/base_script.rb ExecuteBinIntegrationQueue
# Dev   : ruby scripts/base_script.rb ExecuteBinIntegrationQueue

class ExecuteBinIntegrationQueue < BaseScript
  def run
    DB.transaction do
      repo = RawMaterialsApp::RmtDeliveryRepo.new
      snapshot = repo.select_values(:bin_integration_queue, :id, job_no: nil)
      unless snapshot.empty?
        seq_nr = repo.next_document_sequence_number('bin_integration_queue')
        repo.update(:bin_integration_queue, snapshot, job_no: seq_nr)
        RawMaterialsApp::Job::BinIntegrationQueueProcessor.enqueue(seq_nr)
      end

      infodump

      success_response('ok')
    end
  rescue StandardError => e
    failed_response(e.message)
  end

  private

  def infodump
    infodump = <<~STR
      Script: ExecuteBinIntegrationQueue

      Reason for this script:
      -----------------------
      Bin integration service: from old system to new system.
      Nspack will handle bins from the point where bins are added to a rmt tripsheet
      (in order to take them from the delivery to the tripsheet's destination)
      i.e. deliveries will be created in the old system.
      At this point bins will have to exist i.e. bins need to have been fetched from old system.
    STR
    log_infodump(:data_import,
                 :bin_integration,
                 :go_live,
                 infodump)
  end
end
