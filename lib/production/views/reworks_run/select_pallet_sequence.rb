# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class SelectPalletSequence
        def self.call(reworks_run_type_id, pallets_selected)
          ui_rule = UiRules::Compiler.new(:reworks_run_pallet, :select_pallet_sequence, reworks_run_type_id: reworks_run_type_id, pallets_selected: pallets_selected)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.add_notice 'Select representative pallet sequence below'
            page.form do |form|
              form.action "/production/reworks/pallet_sequences/#{pallets_selected}/select_pallet_sequence"
              form.add_field :reworks_run_type_id
              form.add_field :pallets_selected
              form.add_field :id
            end
          end

          layout
        end
      end
    end
  end
end
