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
      extended_fg_code = ProductionApp::ProductSetupRepo.new.calculate_extended_fg_code(packing_specification_item_id)
      extended_fg_id = request_extended_fg_id(extended_fg_code)

      args = { legacy_data: { extended_fg_code: extended_fg_code, extended_fg_id:  extended_fg_id } }
      ProductionApp::PackingSpecificationRepo.new.update_packing_specification_item(packing_specification_item_id, args)
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
  end
end
