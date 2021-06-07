# frozen_string_literal: true

module Crossbeams
  module Config
    # Check client rules.
    #
    # Call like this:
    #   Crossbeams::Config::ClientRuleChecker.rule_passed?('CR_PROD', 'can_mix_cultivar_groups?')
    # to return the value for:
    #   AppConst::CR_PROD.can_mix_cultivar_groups?
    #
    class ClientRuleChecker
      # Check if a client rule passes
      def self.rule_passed?(*args)
        env = args.shift.upcase
        method = args.shift
        klass = AppConst.const_get(env)
        if args.empty?
          klass.send(method.to_sym)
        else
          klass.send(method.to_sym, args)
        end
      end
    end
  end
end
