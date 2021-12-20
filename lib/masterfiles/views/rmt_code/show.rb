# frozen_string_literal: true

module Masterfiles
  module RawMaterials
    module RmtCode
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:rmt_code, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Rmt Code'
              form.view_only!
              form.add_field :rmt_variant_id
              form.add_field :rmt_handling_regime_id
              form.add_field :rmt_code
              form.add_field :description
            end
          end
        end
      end
    end
  end
end
