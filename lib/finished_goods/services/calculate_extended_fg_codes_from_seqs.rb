# frozen_string_literal: true

module FinishedGoodsApp
  class CalculateExtendedFgCodesFromSeqs < BaseService
    attr_reader :repo, :pallet_sequence_ids, :sequence_data, :pallet_ids

    def initialize(pallet_ids)
      @pallet_ids = pallet_ids
      @repo = ProductionApp::ProductSetupRepo.new
    end

    def call
      sequences = repo.sequences_grouped_for_ext_fg(pallet_ids)
      sequences.each do |seq|
        @sequence_data = seq
        @pallet_sequence_ids = seq[:ids]
        calculate_extended_fg_codes
      end

      success_response('Extended FG codes calculated successfully')
    end

    private

    def calculate_extended_fg_codes
      extended_fg_code = nil
      extended_fg_id = nil

      ['-', '_'].each do |pm_join|
        extended_fg_code = repo.calculate_extended_fg_code_from_sequences(sequence_data, packaging_marks_join: pm_join)
        lkp = ProductionApp::LookupExtendedFgCodeId.call(extended_fg_code)
        extended_fg_id = lkp.instance || lkp.message
        break if lkp.success
      end

      args = { legacy_data: { extended_fg_code: extended_fg_code, extended_fg_id:  extended_fg_id } }
      pallet_sequence_ids.each do |id|
        update_pallet_sequence(id, args, extended_fg_id, extended_fg_code)
      end
    end

    def update_pallet_sequence(id, attrs, extended_fg_id, extended_fg_code)
      legacy_data = UtilityFunctions.symbolize_keys(repo.get(:pallet_sequences, id, :legacy_data).to_h)

      return if legacy_data[:extended_fg_code] == extended_fg_code && legacy_data[:extended_fg_code] == extended_fg_id

      attrs[:legacy_data] = legacy_data.merge(attrs[:legacy_data].to_h)
      repo.update(:pallet_sequences, id, attrs)
      repo.log_status(:pallet_sequences, id, AppConst::EXTENDED_FG_CODE_RECALCULATED)
    end
  end
end
