# frozen_string_literal: true

module FinishedGoods
  module Inspection
    module GovtInspectionPallet
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:govt_inspection_pallet, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Govt Inspection Pallet'
              form.view_only!
              form.add_field :pallet_id
              form.add_field :govt_inspection_sheet_id
              form.add_field :passed
              form.add_field :inspected
              form.add_field :inspected_at
              form.add_field :failure_reason_id
              form.add_field :failure_remarks
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
