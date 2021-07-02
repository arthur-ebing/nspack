# frozen_string_literal: true

module FinishedGoods
  module Inspection
    module GovtInspectionPallet
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:govt_inspection_pallet, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Govt Inspection Pallet'
              form.action '/finished_goods/inspection/govt_inspection_pallets'
              form.remote! if remote
              form.add_field :pallet_id
              form.add_field :pallet_number
              form.add_field :govt_inspection_sheet_id
              form.add_field :marketing_varieties
              form.add_field :packed_tm_groups

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
