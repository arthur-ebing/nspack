# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PmMark
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:pm_mark, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'PKG Mark'
              form.view_only!
              form.add_field :mark_id
              form.add_field :description
              form.add_field :active
              rules[:composition_levels].each do |_, v|
                form.add_field v.to_sym
              end
            end
          end

          layout
        end
      end
    end
  end
end
