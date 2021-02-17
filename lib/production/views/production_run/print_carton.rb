# frozen_string_literal: true

module Production
  module Runs
    module ProductionRun
      class PrintCarton
        def self.call(attrs, request_ip, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:production_run_product_setup, :print_barcode, attrs: attrs, request_ip: request_ip, form_values: form_values)
          rules   = ui_rule.compile

          action_url = if AppConst::CR_PROD.use_packing_specifications?
                         "/production/runs/production_runs/#{attrs[:id]}/packing_specification_item/#{attrs[:packing_specification_item_id]}/print_label"
                       else
                         "/production/runs/production_runs/#{attrs[:id]}/product_setup/#{attrs[:product_setup_id]}/print_label"
                       end

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action action_url
              form.remote!
              form.method :update
              form.add_field :product_setup_code
              form.add_field :packing_specification_item_code
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
