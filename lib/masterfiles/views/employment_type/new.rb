# frozen_string_literal: true

module Masterfiles
  module HumanResources
    module EmploymentType
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:employment_type, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Employment Type'
              form.action '/masterfiles/human_resources/employment_types'
              form.remote! if remote
              form.add_field :employment_type_code
            end
          end

          layout
        end
      end
    end
  end
end
