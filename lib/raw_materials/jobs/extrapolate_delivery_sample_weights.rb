# frozen_string_literal: true

module RawMaterialsApp
  module Job
    class ExtrapolateDeliverySampleWeights < BaseQueJob
      self.maximum_retry_count = 0

      def run(rmt_delivery_id)
        RawMaterialsApp::ExtrapolateSampleWeightsForDelivery.call(rmt_delivery_id)

        finish
      end
    end
  end
end
