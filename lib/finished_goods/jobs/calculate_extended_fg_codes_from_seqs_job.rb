# frozen_string_literal: true

module FinishedGoodsApp
  module Job
    class CalculateExtendedFgCodesFromSeqs < BaseQueJob
      def run(pallet_ids)
        DB.transaction do
          res = FinishedGoodsApp::CalculateExtendedFgCodes.call(pallet_ids)
          raise res.message unless res.success
        end
      ensure
        finish
      end
    end
  end
end
