# frozen_string_literal: true

module FinishedGoodsApp
  module Job
    class CalculateExtendedFgCodes < BaseQueJob
      def run(pallets)
        res = FinishedGoodsApp::CalculateExtendedFgCodes.call(pallets)
        raise res.message unless res.success

        finish
      end
    end
  end
end
