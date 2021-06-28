# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class EditPalletDetails
        def self.call(pallet_number, reworks_run_type_id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:reworks_run_pallet, :edit_pallet_details, pallet_number: pallet_number, reworks_run_type_id: reworks_run_type_id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/production/reworks/pallets/#{pallet_number}/edit_pallet_details"
              form.remote!
              form.add_field :pallet_number
              form.add_field :reworks_run_type_id
              form.add_field :fruit_sticker_pm_product_id
              form.add_field :fruit_sticker_pm_product_2_id
              form.add_field :batch_number
            end
          end

          layout
        end
      end
    end
  end
end
