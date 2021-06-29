# frozen_string_literal: true

module ProductionApp
  module Job
    class ApplyRunOrchardChanges < BaseQueJob
      def run(args, user_name)
        res = ProductionApp::ChangeRunOrchard.call(args, user_name)
        raise res.message unless res.success

        finish
      end
    end
  end
end
