# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PmMark
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:pm_mark, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'PM Mark'
              form.view_only!
              form.add_field :mark_id
              # form.add_field :packaging_marks
              form.add_field :description
              form.add_field :active
              rules[:composition_levels].each do |key, _val|
                form.add_field key.to_s.to_sym
              end
            end
          end

          layout
        end
      end
    end
  end
end
