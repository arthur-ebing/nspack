# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PmMark
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:pm_mark, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit PM Mark'
              form.action "/masterfiles/packaging/pm_marks/#{id}"
              form.remote!
              form.method :update
              form.add_field :mark_id
              form.add_field :description
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
