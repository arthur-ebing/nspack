# frozen_string_literal: true

module RawMaterialsApp
  class  BinAssetControlProcessor < BaseService
    attr_reader :repo, :queue_ids, :que_recs, :error_log_ids

    def initialize
      @repo = RawMaterialsApp::BinAssetsRepo.new
    end

    def call
      res = process_bin_asset_control_que
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      # FIXME: What happens when an exception is raised? no feedback/email/log

      success_response('ok')
    end

    private

    def process_bin_asset_control_que # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      repo.transaction do
        @queue_ids = repo.bin_asset_transactions_queue_ids
        @error_log_ids = repo.unresolved_bin_asset_move_error_log_ids
        return ok_response if queue_ids.nil_or_empty? && error_log_ids.nil_or_empty?

        @que_recs = repo.bin_asset_transactions_queue_records_for(queue_ids)
        repo.delete_transactions_queue_records(queue_ids)
        return success_response('Bin Asset Transactions Queue records cleared') unless AppConst::CR_RMT.use_bin_asset_control?

        res = process_bin_asset_control_events
        return res unless res.success

        res = resolve_bin_asset_move_error_logs
        return res unless res.success
      end
      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def process_bin_asset_control_events
      return ok_response if queue_ids.nil_or_empty?

      res = nil
      que_recs.each do |rec|
        res = validate_owner_attributes(rec)
        raise Crossbeams::InfoError, res unless res.success

        res = RawMaterialsApp::ProcessBinAssetControlEvent.call(rec)
        raise Crossbeams::InfoError, res unless res.success
      end
      res
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def validate_owner_attributes(rec)
      rec_ids = repo.transactions_missing_owner_attributes(rec[:bin_event_type], rec[:pallet], Array(rec[:rmt_bin_ids]))
      message = "The following #{rec[:pallet] ? 'pallets' : 'bins'} are missing owner attributes (material owner party and/or container material type) : #{rec_ids.join(', ')}."
      return failed_response(message) unless rec_ids.nil_or_empty?

      ok_response
    end

    def resolve_bin_asset_move_error_logs # rubocop:disable Metrics/AbcSize
      return ok_response if error_log_ids.nil_or_empty?

      repo.bin_asset_move_error_logs_for(error_log_ids).each do |rec|
        res = repo.update_quantity_for_bin_asset_location(rec[:bin_asset_location_id], rec[:quantity])
        next unless res.success

        repo.update_error_logs_for_bin_asset_location(rec[:bin_asset_location_id], { completed: true })
      end
      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end
  end
end
