# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class PrintReworksLabelForSequence
        def self.call(id, pallet_number, carton_label, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:reworks_run_print, :print_seq_cartons, id: id, pallet_number: pallet_number, form_values: form_values, carton_label: carton_label)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/production/reworks/pallet_sequences/#{id}/print_reworks_carton_label_for_sequence"
              form.remote!
              form.add_field :pallet_sequence_id
              form.add_field :pallet_number
              form.add_field :printer
              form.add_field :label_template_id
              form.add_field :no_of_prints
            end
          end

          layout
        end
      end
    end
  end
end
