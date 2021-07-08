# frozen_string_literal: true

module ProductionApp
  module Job
    class ApplyRunCultivarChanges < BaseQueJob
      def run(args, user_name)
        res = ProductionApp::ChangeRunCultivar.call(args, user_name)
        raise res.message unless res.success

        finish
      end
    end
  end
end
