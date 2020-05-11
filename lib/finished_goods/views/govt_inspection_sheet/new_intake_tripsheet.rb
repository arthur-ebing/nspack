# frozen_string_literal: true

module FinishedGoods
  module Inspection
    module GovtInspectionSheet
      class NewIntakeTripsheet
        def self.call(id, mode: :new, form_values: nil, form_errors: nil, remote: false)
          ui_rule = UiRules::Compiler.new(:intake_tripsheet, mode, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption ''
              form.action "/finished_goods/inspection/govt_inspection_sheets/#{id}/create_intake_tripsheet"
              form.remote! if remote
              form.add_field :location_to_id
            end
          end

          layout
        end
      end
    end
  end
end
