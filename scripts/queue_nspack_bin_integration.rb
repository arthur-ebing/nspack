# frozen_string_literal: true

# What this script does:
# ----------------------
# Connects to old Kromco_mes database.
# Reads the 'bin_nspack_integration_queue' table.
# For each unique bin_id in the queue, creates a queue record in the NsPack system- new table 'bin_integration_queue'.
# i.e. uses the bin_id in the source queue , read it's bin_data using vwbins and then create a JSON data object.
# Once the bin data is created as a record in the destination queue, the records are deleted from the source queue.

# Reason for this script:
# -----------------------
# Bin integration service: from old system to new system
# Nspack will handle bins from the point where bins are added to a rmt tripsheet
# (in order to take them from the delivery to the tripsheet's destination)
# i.e. deliveries will be created in the old system.
# At this point bins will have to exist i.e. bins need to have been fetched from old system.

# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb QueueNspackBinIntegration postgres://postgres:postgres@localhost/kromco_local
# Live  : RACK_ENV=production ruby scripts/base_script.rb QueueNspackBinIntegration postgres://postgres:postgres@localhost/kromco_local
# Dev   : ruby scripts/base_script.rb QueueNspackBinIntegration postgres://postgres:postgres@localhost/kromco_local

class QueueNspackBinIntegration < BaseScript
  def run
    DB.transaction do
      @db_conn = legacy_db_connection
      @queued_bins = []

      queue = bin_nspack_integration_queue
      queue.map { |b| b[:bin_id] }.uniq.each do |bin_id|
        insert_bin_integration_queue(bin_id)
      end
      delete_nspack_integration_queue_bin(queue.map { |b| b[:id] })

      infodump

      success_response('ok')
    end
  rescue StandardError => e
    failed_response(e.message)
  ensure
    @db_conn&.disconnect
  end

  private

  def infodump
    infodump = <<~STR
      Script: QueueNspackBinIntegration

      Reason for this script:
      -----------------------
      Bin integration service: from old system to new system.
      Nspack will handle bins from the point where bins are added to a rmt tripsheet
      (in order to take them from the delivery to the tripsheet's destination)
      i.e. deliveries will be created in the old system.
      At this point bins will have to exist i.e. bins need to have been fetched from old system.


      Results:
      --------
      output:
      queued bins = #{@queued_bins}

      If there are any errors the transaction would not have committed
    STR
    log_infodump(:data_import,
                 :bin_integration,
                 :go_live,
                 infodump)
  end

  def legacy_db_connection
    Sequel.connect(args[0])
  rescue Sequel::DatabaseConnectionError => e
    raise e.message
  end

  def bin_nspack_integration_queue
    @db_conn[:bin_nspack_integration_queue].select(:bin_id, :id).all
  end

  def bin_data(id)
    @db_conn[:vwbins]
      .join(:farms, farm_code: Sequel[:vwbins][:farm_code])
      .select(Sequel[:vwbins].*, Sequel[:farms][:remark1_ptlocation].as(:puc_code))
      .where(Sequel[:vwbins][:id] => id)
      .first
  end

  def insert_bin_integration_queue(bin_id)
    DB[:bin_integration_queue].where(bin_id: bin_id).delete
    DB[:bin_integration_queue].insert(bin_id: bin_id, bin_data: bin_data(bin_id).to_json)
    @queued_bins << bin_id
  end

  def delete_nspack_integration_queue_bin(ids)
    @db_conn[:bin_nspack_integration_queue].where(id: ids).delete
  end
end
