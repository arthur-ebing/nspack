# frozen_string_literal: true

module RawMaterialsApp
  module Job
    class ProcessBinAssetControlEvent < BaseQueJob
      def run(args)
        RawMaterialsApp::ProcessBinAssetControlEvent.call(args)

        finish
      end
    end
  end
end
