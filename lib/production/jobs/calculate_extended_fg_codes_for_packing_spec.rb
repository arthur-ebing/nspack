# frozen_string_literal: true

module ProductionApp
  module Job
    class CalculateExtendedFgCodesForPackingSpecs < BaseQueJob
      def run(packing_specification_item_id)
        res = FinishedGoodsApp::CalculateExtendedFgCodesForPackingSpecs.call(packing_specification_item_id)
        raise res.message unless res.success

        finish
      end
    end
  end
end
