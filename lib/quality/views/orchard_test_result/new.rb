# frozen_string_literal: true

module Quality
  module TestResults
    module OrchardTestResult
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:orchard_test_result, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Tests'
              form.action '/quality/test_results/orchard_test_results'
              form.remote! if remote
              form.add_field :orchard_test_type_id
              form.add_field :puc_id
            end
          end

          layout
        end
      end
    end
  end
end
