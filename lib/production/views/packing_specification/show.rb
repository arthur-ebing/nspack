# frozen_string_literal: true

module Production
  module PackingSpecifications
    module PackingSpecification
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:packing_specification, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Packing Specification'
              form.view_only!
              form.add_field :product_setup_template
              form.add_field :packing_specification_code
              form.add_field :description
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
