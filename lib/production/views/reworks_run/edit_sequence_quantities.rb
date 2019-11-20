# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class EditSequenceQuantities
        def self.call(pallet_number)
          ui_rule = UiRules::Compiler.new(:reworks_run_pallet, :quantity, pallet_number: pallet_number)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.add_text rules[:compact_header]
            page.section do |section|
              section.add_grid('production_run_allocated_setups',
                               "/list/reworks_edit_pallet_sequences/grid?key=pallet_number&pallet_number=#{pallet_number}",
                               caption: 'Pallet Sequences')
            end
          end

          layout
        end
      end
    end
  end
end
