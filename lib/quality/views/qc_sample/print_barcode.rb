# frozen_string_literal: true

module Quality
  module Qc
    module QcSample
      class PrintBarcode
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:qc_sample, :print_barcode, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/quality/qc/qc_samples/#{id}/print_barcode"
              form.remote!
              form.method :update
              form.add_field :id
              form.add_field :ref_number
              form.add_field :short_description
              form.add_field :printer
              form.add_field :label_name
              form.add_field :no_of_prints
            end
          end
        end
      end
    end
  end
end
