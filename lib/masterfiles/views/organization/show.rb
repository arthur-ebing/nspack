# frozen_string_literal: true

module Masterfiles
  module Parties
    module Organization
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:organization, :show, id: id)
          rules   = ui_rule.compile
          addresses = MasterfilesApp::PartyRepo.new.addresses_for_party(organization_id: id)
          contact_methods = MasterfilesApp::PartyRepo.new.contact_methods_for_party(organization_id: id)

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.view_only!
              form.add_field :parent_organization
              form.add_field :medium_description
              form.add_field :variant_codes
              form.add_field :short_description
              form.add_text 'Note: The short description should be limited to 2 characters for use with EDIs',
                            dom_id: 'short_desc_warn',
                            hide_on_load: rules[:short_too_long],
                            css_classes: 'orange b'
              form.add_field :long_description
              form.add_field :vat_number
              form.add_field :company_reg_no
              form.add_field :role_names
              form.add_address addresses
              form.add_contact_method contact_methods
            end
          end

          layout
        end
      end
    end
  end
end
