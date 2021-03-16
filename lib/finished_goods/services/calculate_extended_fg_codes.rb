# frozen_string_literal: true

module FinishedGoodsApp
  class CalculateExtendedFgCodes < BaseService
    attr_reader :repo, :pallet_sequence_ids, :packing_specification_item_id

    def initialize(pallet_ids)
      @pallet_ids = pallet_ids
      @repo = ProductionApp::ProductSetupRepo.new
    end

    def call
      packing_specification_item_ids = repo.select_values(:pallet_sequences,
                                                          :packing_specification_item_id,
                                                          { pallet_id: pallet_ids }).uniq

      packing_specification_item_ids.each do |packing_specification_item_id|
        @packing_specification_item_id = packing_specification_item_id
        @pallet_sequence_ids = repo.select_values(:pallet_sequences,
                                                  :id,
                                                  { pallet_id: pallet_ids,
                                                    packing_specification_item_id: packing_specification_item_id })
        calculate_extended_fg_codes
      end

      success_response('Extended FG codes calculated successfully')
    end

    private

    def calculate_extended_fg_codes
      extended_fg_code = nil
      extended_fg_id = nil

      ['-', '_'].each do |pm_join|
        extended_fg_code = repo.calculate_extended_fg_code(packing_specification_item_id, packaging_marks_join: pm_join)
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
      legacy_data = UtilityFunctions.symbolize_keys(get(:pallet_sequences, id, :legacy_data).to_h)

      attrs[:legacy_data] = legacy_data.merge(attrs[:legacy_data].to_h)
      repo.update(:pallet_sequences, id, attrs)
    end
  end
end
