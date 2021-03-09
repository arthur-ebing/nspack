# frozen_string_literal: true

module FinishedGoodsApp
  class CalculateExtendedFgCodesForPackingSpecs < BaseService
    attr_accessor :packing_specification_item_ids

    def initialize(packing_specification_item_ids)
      @packing_specification_item_ids = packing_specification_item_ids
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

    def calculate_extended_fg_codes
      seq_extended_fgs = []
      packing_specification_item_ids.each do |packing_specification_item_id|
        if (extended_fg_code = repo.calculate_extended_fg_code(packing_specification_item_id))
          seq_extended_fgs << { id: packing_specification_item_id, extended_fg_code: extended_fg_code }
        end
      end

      ms_repo = MesscadaApp::MesscadaRepo.new
      seq_extended_fgs.group_by { |h| h[:extended_fg_code] }.each do |k, v|
        extended_fg_id = ms_repo.extended_fg_id(k)
        v.each do |s|
          ms_repo.update_packing_specification_item_extended_fg(s[:id], k, extended_fg_id)
        end
      end
    end

    def repo
      @repo ||= ProductionApp::ProductSetupRepo.new
    end
  end
end
