# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class ShowPalletShippingDetails
        def self.call(pallet_number)
          ui_rule = UiRules::Compiler.new(:reworks_run_pallet, :shipping, pallet_number: pallet_number)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.add_text rules[:compact_header]
          end

          layout
        end
      end
    end
  end
end
