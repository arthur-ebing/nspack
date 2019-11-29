# frozen_string_literal: true

module FinishedGoods
  module Inspection
    module GovtInspectionApiResult
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:govt_inspection_api_result, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Govt Inspection Api Result'
              form.action "/finished_goods/inspection/govt_inspection_api_results/#{id}"
              form.remote!
              form.method :update
              form.add_field :govt_inspection_sheet_id
              form.add_field :govt_inspection_request_doc
              form.add_field :govt_inspection_result_doc
              form.add_field :results_requested
              form.add_field :results_requested_at
              form.add_field :results_received
              form.add_field :results_received_at
              form.add_field :upn_number
            end
          end

          layout
        end
      end
    end
  end
end
