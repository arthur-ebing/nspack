# frozen_string_literal: true

module Production
  module Runs
    module Rebins
      class PrintRebinLabels
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:rebin, :print_rebin_labels, production_run_id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/production/runs/production_runs/#{id}/print_rebin_labels"
              form.remote!
              form.method :update
              form.add_field :printer
              form.add_field :label_template_id
            end
          end

          layout
        end
      end
    end
  end
end
