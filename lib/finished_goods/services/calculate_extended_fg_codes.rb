# frozen_string_literal: true

module FinishedGoodsApp
  class CalculateExtendedFgCodes < BaseService
    attr_accessor :pallet_ids

    def initialize(pallet_ids)
      @pallet_ids = pallet_ids
    end

    def call
      repo.transaction do
        calculate_extended_fg_codes
      end

      success_response('Extended FG codes calculated successfully')
    rescue StandardError => e
      failed_response(e.message)
    end

    private

    def calculate_extended_fg_codes # rubocop:disable Metrics/AbcSize
      seq_extended_fgs = []
      repo.select_values(:pallet_sequences, %i[id packing_specification_item_id], pallet_id: pallet_ids).each do |id, packing_specification_item_id|
        if (extended_fg_code = repo.calculate_extended_fg_code(packing_specification_item_id))
          seq_extended_fgs << { id: id, extended_fg_code: extended_fg_code }
        end
      end

      ms_repo = MesscadaApp::MesscadaRepo.new
      seq_extended_fgs.group_by { |h| h[:extended_fg_code] }.each do |k, v|
        extended_fg_id = ms_repo.extended_fg_id(k)
        v.each do |s|
          ms_repo.update_pallet_sequence_extended_fg(s[:id], k, extended_fg_id)
        end
      end
    end

    def repo
      @repo ||= ProductionApp::ProductSetupRepo.new
    end
  end
end
