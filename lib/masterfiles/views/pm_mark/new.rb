# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PmMark
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:pm_mark, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New PM Mark'
              form.action '/masterfiles/packaging/pm_marks'
              form.remote! if remote
              form.add_field :mark_id
              form.add_field :description
              rules[:composition_levels].each do |_key, val|
                form.add_field val.to_sym
              end
            end
          end

          layout
        end
      end
    end
  end
end
