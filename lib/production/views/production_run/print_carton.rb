# frozen_string_literal: true

module Production
  module Runs
    module ProductionRun
      class PrintCarton
        def self.call(id, product_setup_id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:production_run_product_setup, :print_barcode, id: id, product_setup_id: product_setup_id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/production/runs/production_runs/#{id}/product_setup/#{product_setup_id}/print_label"
              form.remote!
              form.method :update
              form.add_field :product_setup_code
              form.add_field :printer
              form.add_field :label_template_id
              form.add_field :no_of_prints
            end
          end

          layout
        end
      end
    end
  end
end
