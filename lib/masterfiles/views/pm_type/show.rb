# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PmType
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:pm_type, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Pm Type'
              form.view_only!
              form.add_field :pm_composition_level_id
              form.add_field :pm_type_code
              form.add_field :description
              form.add_field :active
              form.add_field :pm_subtypes
            end
          end

          layout
        end
      end
    end
  end
end
