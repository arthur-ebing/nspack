# frozen_string_literal: true

module Production
  module Runs
    module ProductionRun
      class SelectTemplate
        def self.call(id, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:production_run, :template, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.add_text 'Select Product Setup Template', wrapper: :h2
            page.add_text rules[:compact_header]
            page.form do |form|
              form.action "/production/runs/production_runs/#{id}/select_template"
              form.remote! if remote
              form.add_field :product_setup_template_id
            end
          end

          layout
        end
      end
    end
  end
end
