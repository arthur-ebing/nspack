# frozen_string_literal: true

module Masterfiles
  module RawMaterials
    module RmtHandlingRegime
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:rmt_handling_regime, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Rmt Handling Regime'
              form.action "/masterfiles/raw_materials/rmt_handling_regimes/#{id}"
              form.remote!
              form.method :update
              form.add_field :regime_code
              form.add_field :description
              form.add_field :for_packing
            end
          end
        end
      end
    end
  end
end
