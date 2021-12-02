# frozen_string_literal: true

module Masterfiles
  module RawMaterials
    module RmtHandlingRegime
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:rmt_handling_regime, :new, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Rmt Handling Regime'
              form.action '/masterfiles/raw_materials/rmt_handling_regimes'
              form.remote! if remote
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
