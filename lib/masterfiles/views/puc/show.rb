# frozen_string_literal: true

module Masterfiles
  module Farms
    module Puc
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:puc, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Puc'
              form.view_only!
              form.add_field :puc_code
              form.add_field :gap_code
              form.add_field :gap_code_valid_from
              form.add_field :gap_code_valid_until
              form.add_field :active
              form.add_field :farms
            end
          end

          layout
        end
      end
    end
  end
end
