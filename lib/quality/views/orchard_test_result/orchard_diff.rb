# frozen_string_literal: true

module Quality
  module TestResults
    module OrchardTestResult
      class OrchardDiff
        def self.call
          ui_rule = UiRules::Compiler.new(:orchard_test_result, :diff)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.caption = 'Phyto Headers'
              section.add_diff :header
            end
          end

          layout
        end
      end
    end
  end
end
