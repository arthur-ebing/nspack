# frozen_string_literal: true

module FinishedGoods
  module Inspection
    module GovtInspectionPallet
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:govt_inspection_pallet, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Govt Inspection Pallet'
              form.action "/finished_goods/inspection/govt_inspection_pallets/#{id}"
              form.remote!
              form.method :update
              form.add_field :pallet_id
              form.add_field :govt_inspection_sheet_id
              form.add_field :passed
              form.add_field :inspected
              form.add_field :inspected_at
              form.add_field :failure_reason_id
              form.add_field :failure_remarks
            end
          end

          layout
        end
      end
    end
  end
end
