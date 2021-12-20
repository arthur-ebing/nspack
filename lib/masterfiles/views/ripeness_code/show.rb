# frozen_string_literal: true

module Masterfiles
  module RawMaterials
    module RipenessCode
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:ripeness_code, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Ripeness Code'
              form.view_only!
              form.add_field :ripeness_code
              form.add_field :description
              form.add_field :legacy_code
            end
          end
        end
      end
    end
  end
end
