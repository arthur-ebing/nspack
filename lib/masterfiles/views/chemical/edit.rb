# frozen_string_literal: true

module Masterfiles
  module Quality
    module Chemical
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:chemical, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Chemical'
              form.action "/masterfiles/quality/chemicals/#{id}"
              form.remote!
              form.method :update
              form.add_field :chemical_name
              form.add_field :description
              form.add_field :eu_max_level
              form.add_field :arfd_max_level
              form.add_field :orchard_chemical
              form.add_field :drench_chemical
              form.add_field :packline_chemical
            end
          end
        end
      end
    end
  end
end
