# frozen_string_literal: true

module Masterfiles
  module Fruit
    module Grade
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:grade, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Grade'
              form.action '/masterfiles/fruit/grades'
              form.remote! if remote
              form.add_field :grade_code
              form.add_field :description
              form.add_field :rmt_grade
            end
          end

          layout
        end
      end
    end
  end
end
