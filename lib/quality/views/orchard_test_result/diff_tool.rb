# frozen_string_literal: true

module Quality
  module TestResults
    module OrchardTestResult
      class DiffTool
        def self.call(mode, phyto_res)
          ui_rule = UiRules::Compiler.new(:orchard_test_result_diff, mode, phyto_res: phyto_res)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_diff :diff
            end
          end

          layout
        end
      end
    end
  end
end
