# frozen_string_literal: true

module FinishedGoods
  module Inspection
    module GovtInspectionPalletApiResult
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:govt_inspection_pallet_api_result, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Govt Inspection Pallet Api Result'
              form.action '/finished_goods/inspection/govt_inspection_pallet_api_results'
              form.remote! if remote
              form.add_field :passed
              form.add_field :failure_reasons
              form.add_field :govt_inspection_pallet_id
              form.add_field :govt_inspection_api_result_id
            end
          end

          layout
        end
      end
    end
  end
end
