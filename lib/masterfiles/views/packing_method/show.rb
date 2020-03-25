# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PackingMethod
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:packing_method, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Packing Method'
              form.view_only!
              form.add_field :packing_method_code
              form.add_field :description
              form.add_field :actual_count_reduction_factor
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
