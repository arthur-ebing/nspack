# frozen_string_literal: true

module UiRules
  class PmBomsProductRule < Base
    def generate_rules
      @repo = MasterfilesApp::BomRepo.new
      make_form_object
      apply_form_values

      @rules[:is_edit] = @mode == :edit

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      add_behaviours if %i[new edit].include? @mode

      form_name 'pm_boms_product'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      pm_subtype = @repo.find_pm_subtype(@form_object.pm_subtype_id)
      pm_subtype_id_label = "#{pm_subtype&.pm_type_code} - #{pm_subtype&.subtype_code}"
      pm_product_id_label = @repo.find_hash(:pm_products,  @form_object.pm_product_id)[:erp_code]
      pm_bom_id_label = @repo.find_hash(:pm_boms, @form_object.pm_bom_id)[:bom_code]
      uom_id_label = @repo.find_hash(:uoms, @form_object.uom_id)[:uom_code]
      fields[:pm_subtype_id] = { renderer: :label, with_value: pm_subtype_id_label, caption: 'Pm Subtype' }
      fields[:pm_product_id] = { renderer: :label, with_value: pm_product_id_label, caption: 'Pm Product' }
      fields[:pm_bom_id] = { renderer: :label, with_value: pm_bom_id_label, caption: 'Pm Bom' }
      fields[:uom_id] = { renderer: :label, with_value: uom_id_label, caption: 'Unit Of Measure' }
      fields[:quantity] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields  # rubocop:disable Metrics/AbcSize
      pm_bom_id = @options[:pm_bom_id] || @repo.find_pm_boms_product(@options[:id]).pm_bom_id
      pm_bom_id_label = @repo.find_pm_bom(pm_bom_id)&.bom_code
      subtypes = @rules[:is_edit] ? @repo.for_select_pm_type_subtypes : @repo.for_select_pm_type_subtypes(pm_bom_id)
      {
        pm_bom_id: { renderer: :hidden, value: pm_bom_id },
        pm_bom: { renderer: :label, with_value: pm_bom_id_label, caption: 'PM Bom', readonly: true },
        pm_subtype_id: { renderer: :select,
                         options: subtypes,
                         disabled_options: @repo.for_select_inactive_pm_subtypes,
                         caption: 'PM Subtype',
                         prompt: 'Select Subtype',
                         searchable: true,
                         remove_search_for_small_list: false,
                         required: true },
        pm_product_id: { renderer: :select,
                         options: @repo.for_select_pm_products,
                         disabled_options: @repo.for_select_inactive_pm_products,
                         caption: 'PM Product',
                         prompt: 'Select Product',
                         searchable: true,
                         remove_search_for_small_list: false,
                         required: true },
        uom_id: { renderer: :select,
                  options: @repo.for_select_pm_uoms(AppConst::UOM_TYPE),
                  disabled_options: MasterfilesApp::GeneralRepo.new.for_select_inactive_uoms,
                  caption: 'Unit of Measure',
                  required: true },
        quantity: { renderer: :number, required: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      res = @repo.find_pm_boms_product(@options[:id])
      @form_object = OpenStruct.new(res.to_h.merge(pm_subtype_id: @repo.get(:pm_products, res.pm_product_id, :pm_subtype_id)))
    end

    def make_new_form_object
      @form_object = OpenStruct.new(pm_bom_id: @options[:pm_bom_id],
                                    pm_product_id: nil,
                                    uom_id: nil,
                                    quantity: nil)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :pm_subtype_id,
                                  notify: [{ url: '/masterfiles/packaging/pm_boms_products/pm_subtype_changed' }]
      end
    end
  end
end
