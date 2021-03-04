# frozen_string_literal: true

module Masterfiles
  module Finance
    module Incoterm
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:incoterm, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Incoterm'
              form.action "/masterfiles/finance/incoterms/#{id}"
              form.remote!
              form.method :update
              form.add_field :incoterm
            end
          end

          layout
        end
      end
    end
  end
end
