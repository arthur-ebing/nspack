# frozen_string_literal: true

module FinishedGoods
  module Inspection
    module GovtInspectionPalletApiResult
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:govt_inspection_pallet_api_result, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Govt Inspection Pallet Api Result'
              form.view_only!
              form.add_field :passed
              form.add_field :failure_reasons
              form.add_field :govt_inspection_pallet_id
              form.add_field :govt_inspection_api_result_id
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
