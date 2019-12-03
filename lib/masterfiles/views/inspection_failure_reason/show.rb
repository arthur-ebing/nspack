# frozen_string_literal: true

module Masterfiles
  module Quality
    module InspectionFailureReason
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:inspection_failure_reason, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Inspection Failure Reason'
              form.view_only!
              form.add_field :inspection_failure_type_id
              form.add_field :failure_reason
              form.add_field :description
              form.add_field :main_factor
              form.add_field :secondary_factor
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
