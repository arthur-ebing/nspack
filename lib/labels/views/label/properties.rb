# frozen_string_literal: true

module Labels
  module Labels
    module Label
      class Properties
        def self.call(id, form_values = nil, form_errors = nil)
          ui_rule = UiRules::Compiler.new(:label, :properties, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/labels/labels/labels/#{id}"
              form.remote!
              form.method :update
              form.add_field :label_name
              form.add_field :variable_set
              Crossbeams::Config::ExtendedColumnDefinitions.extended_columns_for_view(:labels, form)
            end
          end

          layout
        end
      end
    end
  end
end
