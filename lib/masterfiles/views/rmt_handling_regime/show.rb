# frozen_string_literal: true

module Masterfiles
  module RawMaterials
    module RmtHandlingRegime
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:rmt_handling_regime, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Rmt Handling Regime'
              form.view_only!
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
