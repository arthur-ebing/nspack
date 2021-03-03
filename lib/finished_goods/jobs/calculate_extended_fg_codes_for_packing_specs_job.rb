# frozen_string_literal: true

module FinishedGoodsApp
  module Job
    class CalculateExtendedFgCodesForPackingSpecs < BaseQueJob
      def run(packing_specification_item_ids)
        res = FinishedGoodsApp::CalculateExtendedFgCodesForPackingSpecs.call(packing_specification_item_ids)
        raise res.message unless res.success

        finish
      end
    end
  end
end
