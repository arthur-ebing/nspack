# frozen_string_literal: true

module Masterfiles
  module Parties
    module Organization
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:organization, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action '/masterfiles/parties/organizations'
              form.remote! if remote
              form.add_field :parent_id
              form.add_field :medium_description
              form.add_field :short_description
              form.add_text 'Note: The short description should be limited to 2 characters for use with EDIs',
                            dom_id: 'short_desc_warn',
                            hide_on_load: rules[:short_too_long],
                            css_classes: 'orange b'
              form.add_field :long_description
              form.add_field :vat_number
              form.add_field :company_reg_no
              form.add_field :role_ids
            end
          end

          layout
        end
      end
    end
  end
end
