# frozen_string_literal: true

module Masterfiles
  module RawMaterials
    module RmtVariant
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:rmt_variant, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Rmt Variant'
              form.view_only!
              form.add_field :cultivar_id
              form.add_field :rmt_variant_code
              form.add_field :description
            end
          end
        end
      end
    end
  end
end
