# frozen_string_literal: true

module Masterfiles
  module Quality
    module Chemical
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:chemical, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Chemical'
              form.view_only!
              form.add_field :chemical_name
              form.add_field :description
              form.add_field :eu_max_level
              form.add_field :arfd_max_level
              form.add_field :orchard_chemical
              form.add_field :drench_chemical
              form.add_field :packline_chemical
              form.add_field :active
            end
          end
        end
      end
    end
  end
end
