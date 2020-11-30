# frozen_string_literal: true

module Masterfiles
  module RawMaterials
    module RmtSize
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:rmt_size, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Rmt Size'
              form.view_only!
              form.add_field :size_code
              form.add_field :description
            end
          end

          layout
        end
      end
    end
  end
end
