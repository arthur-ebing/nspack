# frozen_string_literal: true

module Masterfiles
  module HumanResources
    module ContractWorker
      class PrintBarcode
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:contract_worker, :print_barcode, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/masterfiles/human_resources/contract_workers/#{id}/print_barcode"
              form.remote!
              form.method :update
              form.add_field :personnel_number
              form.add_field :printer
              form.add_field :no_of_prints
            end
          end

          layout
        end
      end
    end
  end
end
