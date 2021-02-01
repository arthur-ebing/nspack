# frozen_string_literal: true

module Masterfiles
  module Packaging
    module InnerPmMark
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:inner_pm_mark, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Inner Pm Mark'
              form.action "/masterfiles/packaging/inner_pm_marks/#{id}"
              form.remote!
              form.method :update
              form.add_field :inner_pm_mark_code
              form.add_field :description
              form.add_field :tu_mark
              form.add_field :ri_mark
              form.add_field :ru_mark
            end
          end

          layout
        end
      end
    end
  end
end
