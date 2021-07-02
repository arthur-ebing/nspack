# frozen_string_literal: true

module RawMaterials
  module Deliveries
    module RmtBin
      class PrePrintBinLabels
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:pre_print_bin_label, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action '/raw_materials/deliveries/pre_print_bin_labels'
              form.remote! if remote
              form.add_field :farm_id
              form.add_field :puc_id
              form.add_field :orchard_id
              form.add_field :cultivar_id
              form.add_field :no_of_prints
              form.add_field :printer
              form.add_field :bin_label
            end
          end

          layout
        end
      end
    end
  end
end
