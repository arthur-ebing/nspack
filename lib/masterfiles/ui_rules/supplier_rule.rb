# frozen_string_literal: true

module UiRules
  class SupplierRule < Base
    def generate_rules
      @repo = MasterfilesApp::SupplierRepo.new
      @party_repo = MasterfilesApp::PartyRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'supplier'
    end

    def set_show_fields
      fields[:supplier_party_role_id] = { renderer: :label,
                                          with_value: @form_object.supplier,
                                          caption: 'Supplier' }
      fields[:supplier_group_ids] = { renderer: :list,
                                      caption: 'Supplier Groups',
                                      items: @form_object.supplier_group_codes }
      fields[:farm_ids] = { renderer: :list,
                            caption: 'Farms',
                            items: @form_object.farm_codes }
      fields[:active] = { renderer: :label,
                          as_boolean: true }
    end

    def common_fields
      {
        supplier_party_role_id: { renderer: :select,
                                  options: @party_repo.for_select_party_roles(AppConst::ROLE_SUPPLIER),
                                  disabled_options: @party_repo.for_select_inactive_party_roles(AppConst::ROLE_SUPPLIER),
                                  caption: 'Supplier',
                                  required: true },
        supplier_group_ids: { renderer: :multi,
                              options: @repo.for_select_supplier_groups,
                              selected: @form_object.supplier_group_ids,
                              caption: 'Supplier Groups',
                              required: true },
        farm_ids: { renderer: :multi,
                    options: MasterfilesApp::FarmRepo.new.for_select_farms,
                    selected: @form_object.farm_ids,
                    caption: 'Farms',
                    required: true }
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
      @form_object = OpenStruct.new(supplier_party_role_id: nil,
                                    supplier_group_ids: nil,
                                    farm_ids: nil)
    end
  end
end
