# frozen_string_literal: true

module FinishedGoods
  module Inspection
    module GovtInspectionApiResult
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:govt_inspection_api_result, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Govt Inspection Api Result'
              form.view_only!
              form.add_field :govt_inspection_sheet_id
              form.add_field :govt_inspection_request_doc
              form.add_field :govt_inspection_result_doc
              form.add_field :results_requested
              form.add_field :results_requested_at
              form.add_field :results_received
              form.add_field :results_received_at
              form.add_field :upn_number
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
