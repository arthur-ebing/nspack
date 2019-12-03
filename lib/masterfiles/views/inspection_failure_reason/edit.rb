# frozen_string_literal: true

module Masterfiles
  module Quality
    module InspectionFailureReason
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:inspection_failure_reason, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Inspection Failure Reason'
              form.action "/masterfiles/quality/inspection_failure_reasons/#{id}"
              form.remote!
              form.method :update
              form.add_field :inspection_failure_type_id
              form.add_field :failure_reason
              form.add_field :description
              form.add_field :main_factor
              form.add_field :secondary_factor
            end
          end

          layout
        end
      end
    end
  end
end
