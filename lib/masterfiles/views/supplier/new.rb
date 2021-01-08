# frozen_string_literal: true

module Masterfiles
  module Parties
    module Supplier
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:supplier, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Supplier'
              form.action '/masterfiles/parties/suppliers'
              form.remote! if remote
              form.add_field :supplier
              form.add_field :supplier_party_role_id

              # Organization
              form.add_field :medium_description
              form.add_field :short_description
              form.add_field :long_description
              form.add_field :company_reg_no
              form.add_field :vat_number

              form.add_field :farm_ids
              form.add_field :supplier_group_ids
            end
          end

          layout
        end
      end
    end
  end
end
