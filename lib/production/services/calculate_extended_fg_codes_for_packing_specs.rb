# frozen_string_literal: true

module ProductionApp
  class CalculateExtendedFgCodesForPackingSpecs < BaseService
    attr_reader :packing_specification_item_id

    def initialize(packing_specification_item_id)
      @packing_specification_item_id = packing_specification_item_id
    end

    def call
      calculate_extended_fg_codes

      success_response('Extended FG codes calculated successfully')
    end

    private

    def calculate_extended_fg_codes
      extended_fg_code = nil
      extended_fg_id = nil

      ['-', '_'].each do |pm_join|
        extended_fg_code = ProductionApp::ProductSetupRepo.new.calculate_extended_fg_code(packing_specification_item_id, packaging_marks_join: pm_join)
        lkp = ProductionApp::LookupExtendedFgCodeId.call(extended_fg_code)
        extended_fg_id = lkp.instance || lkp.message
        break if lkp.success
      end

      args = { legacy_data: { extended_fg_code: extended_fg_code, extended_fg_id: extended_fg_id } }
      ProductionApp::PackingSpecificationRepo.new.update_packing_specification_item(packing_specification_item_id, args)
    end
  end
end
