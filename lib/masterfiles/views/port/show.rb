# frozen_string_literal: true

module Masterfiles
  module Shipping
    module Port
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:port, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Port'
              form.view_only!
              form.add_field :port_code
              form.add_field :description
              form.add_field :city_id
              form.add_field :port_type_ids
              form.add_field :voyage_type_ids
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
