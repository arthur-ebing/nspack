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
        extended_fg_id = request_extended_fg_id(extended_fg_code)
        break if extended_fg_id.to_i.positive?
      end

      args = { legacy_data: { extended_fg_code: extended_fg_code, extended_fg_id:  extended_fg_id } }
      pallet_sequence_ids.each do |id|
        update_pallet_sequence(id, args)
      end
    end

    def request_extended_fg_id(extended_fg_code)
      url = "#{AppConst::RMT_INTEGRATION_SERVER_URI}/services/integration/get_extended_fg?extended_fg_code=#{extended_fg_code}"
      http = Crossbeams::HTTPCalls.new
      res = http.request_get(url)
      return res.message unless res.success

      instance = res.instance.body
      return 'Nothing returned from MES' if instance.nil_or_empty?

      JSON.parse(instance)
    end

    def update_pallet_sequence(id, attrs)
      legacy_data = UtilityFunctions.symbolize_keys(repo.get(:pallet_sequences, id, :legacy_data).to_h)

      attrs[:legacy_data] = legacy_data.merge(attrs[:legacy_data].to_h)
      repo.update(:pallet_sequences, id, attrs)
    end
  end
end
