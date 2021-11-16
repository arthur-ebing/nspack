# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class ReprintPalletCartonLabels
        def self.call(pallet_number, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:reworks_run_print, :print_barcode, pallet_number: pallet_number, form_values: form_values, carton_label: true)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/production/reworks/pallets/#{pallet_number}/reprint_pallet_carton_labels"
              form.remote!
              form.add_field :pallet_number
              form.add_field :printer
              form.add_field :label_template_id
            end
          end

          layout
        end
      end
    end
  end
end
