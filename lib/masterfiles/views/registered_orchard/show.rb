# frozen_string_literal: true

module Masterfiles
  module Farms
    module RegisteredOrchard
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:registered_orchard, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Registered Orchard'
              form.view_only!
              form.add_field :orchard_code
              form.add_field :cultivar_code
              form.add_field :puc_code
              form.add_field :description
              form.add_field :marketing_orchard
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
