# frozen_string_literal: true

module UiRules
  class CustomerRule < Base
    def generate_rules
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      add_behaviours if %i[new].include? @mode

      form_name 'customer'
    end

    def set_show_fields
      fields[:currencies] = { renderer: :list,
                              items: @form_object.currencies }
      fields[:default_currency] = { renderer: :label }
      fields[:contact_people] = { renderer: :list,
                                  items: @form_object.contact_people }
      fields[:customer] = { renderer: :label }
      fields[:active] = { renderer: :label,
                          as_boolean: true }
    end

    def common_fields
      party_role_options = [['Create New Organization'], [@form_object.customer, @form_object.customer_party_role_id]] - [[nil, nil]]
      party_role_options += @party_repo.for_select_party_roles_exclude(AppConst::ROLE_CUSTOMER, where: { person_id: nil })
      hide_org_renderers = @form_object.customer_party_role_id != 'Create New Organization'
      {
        currency_ids: { renderer: :multi,
                        options: @finance_repo.for_select_currencies,
                        selected: @form_object.currency_ids,
                        caption: 'Currencies' },
        default_currency_id: { renderer: :select,
                               options: @repo.for_select_currencies,
                               disabled_options: @repo.for_select_inactive_currencies,
                               prompt: true,
                               required: true,
                               caption: 'Default Currency' },
        contact_person_ids: { renderer: :multi,
                              options: @party_repo.for_select_party_roles(AppConst::ROLE_CUSTOMER_CONTACT_PERSON),
                              selected: @form_object.contact_person_ids,
                              caption: 'Contact People' },
        customer: { caption: 'Customer',
                    renderer: :label,
                    hide_on_load: @mode == :new },
        customer_party_role_id: { caption: 'Customer',
                                  renderer: :select,
                                  options: party_role_options,
                                  sort_items: false,
                                  searchable: true,
                                  hide_on_load: @mode == :edit,
                                  prompt: true,
                                  required: true },
        # Organization
        medium_description: { caption: 'Organization Code',
                              hide_on_load: hide_org_renderers },
        short_description: { hide_on_load: hide_org_renderers },
        long_description: { hide_on_load: hide_org_renderers },
        company_reg_no: { hide_on_load: hide_org_renderers },
        vat_number: { hide_on_load: hide_org_renderers }
      }
    end

    def make_form_object
      @repo = MasterfilesApp::FinanceRepo.new
      @party_repo = MasterfilesApp::PartyRepo.new
      @finance_repo = MasterfilesApp::FinanceRepo.new

      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_customer(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(default_currency_id: @repo.get_id(:currencies, currency: 'ZAR'),
                                    customer_party_role_id: nil)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :customer_party_role_id, notify: [{ url: '/masterfiles/finance/customers/customer_party_role_changed' }]
      end
    end
  end
end
