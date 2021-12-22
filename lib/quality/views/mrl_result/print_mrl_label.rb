# frozen_string_literal: true

module Quality
  module Mrl
    module MrlResult
      class PrintMrlLabel
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:mrl_result, :print_mrl_label, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/quality/mrl/mrl_results/#{id}/print_mrl_labels"
              form.remote!
              form.method :update
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
