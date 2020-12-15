# frozen_string_literal: true

module Crossbeams
  # Documenting module for client run rules.
  # This module mixes in the self-documenting of methods.
  #
  # Each method in an including class should have a keyword argument
  # named "explain", which defaults to false.
  # When passed in as true, the method should just return a description of itself.
  #
  # e.g.
  #   def go_left_or_right?(explain: false)
  #     return 'What this does and when is it useful' if explain
  #
  #     true # The actual return value of the method.
  #   end
  module AutoDocumentation
    EXPLAIN_SET = %i[key explain].freeze

    def rule_name
      self.class.name.sub('Crossbeams::', '').gsub(/([A-Z])/, ' \1').strip
    end

    def to_table
      rules = public_methods(false) - [:settings]
      rules.sort.map do |m|
        params = method(m).parameters
        has_explain = params.include?(EXPLAIN_SET)
        rest = params.reject { |k| k == EXPLAIN_SET }

        {
          method: _method_nm(m, rest),
          description: _description(m, rest, has_explain),
          value: _value(m, rest)
        }
      end
    end

    def _description(meth, rest, has_explain)
      if has_explain
        if rest.empty?
          send(meth, explain: true)
        else
          send(meth, *rest.map(&:last), explain: true)
        end
      else
        'I AM UNDOCUMENTED... FIXME PLEASE!'
      end
    end

    def _method_nm(meth, rest)
      if rest.empty?
        meth
      else
        "#{meth}(#{rest.map(&:last).join(', ')})"
      end
    end

    def _value(meth, rest)
      if rest.empty?
        send(meth)
      else
        'DYNAMIC - depends on input'
      end
    end
  end
end
