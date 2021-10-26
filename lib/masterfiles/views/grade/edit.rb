# frozen_string_literal: true

module Masterfiles
  module Fruit
    module Grade
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:grade, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Grade'
              form.action "/masterfiles/fruit/grades/#{id}"
              form.remote!
              form.method :update
              form.add_field :grade_code
              form.add_field :description
              form.add_field :rmt_grade
              form.add_field :qa_level
              form.add_field :inspection_class
            end
          end
        end
      end
    end
  end
end
