# frozen_string_literal: true

module UiRules
  class SupplierRule < Base
    def generate_rules
      @repo = MasterfilesApp::SupplierRepo.new
      @party_repo = MasterfilesApp::PartyRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields
      add_approve_behaviours if %i[new].include? @mode

      set_show_fields if %i[show reopen].include? @mode

      form_name 'supplier'
    end

    def set_show_fields
      fields[:supplier] = { renderer: :label }
      fields[:supplier_group_ids] = { renderer: :list,
                                      caption: 'Supplier Groups',
                                      items: @form_object.supplier_group_codes }
      fields[:farm_ids] = { caption: 'Farms',
                            renderer: :list,
                            items: @form_object.farm_codes }
      fields[:active] = { renderer: :label,
                          as_boolean: true }
    end

    def common_fields
      party_role_options = @party_repo.for_select_party_roles_exclude(AppConst::ROLE_SUPPLIER, where: { person_id: nil })
      party_role_options << ['Create New Orginization', 'O']
      {
        supplier: { caption: 'Supplier',
                    renderer: :label,
                    hide_on_load: @mode == :new },
        party_role_id: { caption: 'Supplier',
                         renderer: :select,
                         options: party_role_options,
                         sort_items: false,
                         searchable: true,
                         prompt: true,
                         hide_on_load: @mode == :edit,
                         required: true },
        supplier_group_ids: { caption: 'Supplier Groups',
                              renderer: :multi,
                              options: @repo.for_select_supplier_groups,
                              selected: @form_object.supplier_group_ids,
                              required: true },
        farm_ids: { caption: 'Farms',
                    renderer: :multi,
                    options: MasterfilesApp::FarmRepo.new.for_select_farms,
                    selected: @form_object.farm_ids,
                    required: true },
        # Organization
        medium_description: { caption: 'Organization Code',
                              hide_on_load: true },
        short_description: { hide_on_load: true },
        long_description: { hide_on_load: true },
        company_reg_no: { hide_on_load: true },
        vat_number: { hide_on_load: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_supplier(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(party_role_id: nil,
                                    supplier_group_ids: nil,
                                    farm_ids: nil)
    end

    private

    def add_approve_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :party_role_id, notify: [{ url: '/masterfiles/parties/suppliers/supplier_party_role_changed' }]
      end
    end
  end
end
