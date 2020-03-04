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
            page.form do |form|
              form.action "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{pallets_selected.join(',')}/edit_representative_pallet_sequence"
              form.add_field :reworks_run_type_id
              form.add_field :pallet_sequence_id
              form.add_field :reworks_run_type
              form.add_field :pallets_selected
              form.add_notice 'Select a representative pallet sequence for update', inline_caption: true
              form.add_field :id
            end
          end

          layout
        end
      end
    end
  end
end
