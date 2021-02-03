# frozen_string_literal: true

module Masterfiles
  module Packaging
    module InnerPmMark
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:inner_pm_mark, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Inner PKG Mark'
              form.view_only!
              form.add_field :inner_pm_mark_code
              form.add_field :description
              form.add_field :tu_mark
              form.add_field :ri_mark
              form.add_field :ru_mark
            end
          end

          layout
        end
      end
    end
  end
end
