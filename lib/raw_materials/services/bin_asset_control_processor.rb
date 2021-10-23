# frozen_string_literal: true

module RawMaterialsApp
  class  BinAssetControlProcessor < BaseService
    attr_reader :repo, :queue_ids, :error_log_ids

    def initialize
      @repo = RawMaterialsApp::BinAssetsRepo.new
      @queue_ids = repo.bin_asset_transactions_queue_ids
      @error_log_ids = repo.unresolved_bin_asset_move_error_log_ids
    end

    def call
      return delete_transactions_queue_records unless AppConst::CR_RMT.use_bin_asset_control?

      res = bin_asset_control
      raise Crossbeams::FrameworkError, unwrap_failed_response(res) unless res.success

      res = resolve_bin_asset_move_error_logs
      raise Crossbeams::FrameworkError, unwrap_failed_response(res) unless res.success

      success_response('ok')
    end

    private

    def delete_transactions_queue_records
      repo.delete_transactions_queue_records(queue_ids)
    end

    def bin_asset_control
      return ok_response if queue_ids.nil_or_empty?

      res = validate_owner_attributes
      return res unless res.success

      res = process_bin_asset_control_events
      return res unless res.success

      ok_response
    end

    def validate_owner_attributes
      message = ' are missing owner attributes (material owner party and/or container material type)'
      rmt_bin_ids = repo.rmt_bins_missing_owner_attributes(queue_ids)
      return failed_response("Rmt bins: #{rmt_bin_ids.join(', ')} #{message}") unless rmt_bin_ids.nil_or_empty?

      pallet_ids = repo.pallets_missing_owner_attributes(queue_ids)
      return failed_response("Pallets: #{pallet_ids.join(', ')} #{message}") unless pallet_ids.nil_or_empty?

      ok_response
    end

    def process_bin_asset_control_events
      res = nil
      repo.transaction do
        repo.bin_asset_control_events_for(queue_ids).each do |rec|
          # QUESTION: Job or process ???
          # RawMaterialsApp::Job::ProcessBinAssetControlEvent.enqueue(rec)
          res = RawMaterialsApp::ProcessBinAssetControlEvent.call(rec)
          return res unless res.success
        end
        delete_transactions_queue_records
      end
      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def resolve_bin_asset_move_error_logs # rubocop:disable Metrics/AbcSize
      return ok_response if error_log_ids.nil_or_empty?

      repo.transaction do
        repo.bin_asset_move_error_logs_for(error_log_ids).each do |rec|
          res = repo.update_quantity_for_bin_asset_location(rec[:bin_asset_location_id], rec[:quantity])
          next unless res.success

          repo.update_error_logs_for_bin_asset_location(rec[:bin_asset_location_id], { completed: true })
        end
      end
      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end
  end
end
