# frozen_string_literal: true

module UiRules
  class PackingSpecificationItemRule < Base
    def generate_rules
      @repo = ProductionApp::PackingSpecificationRepo.new
      @bom_repo = MasterfilesApp::BomRepo.new
      @setup_repo = ProductionApp::ProductSetupRepo.new
      make_form_object
      apply_form_values

      @rules[:rebin] ||= @repo.get(:product_setups, :rebin, @form_object.product_setup_id) || false

      set_show_fields if %i[show].include? @mode

      if %i[new edit].include? @mode
        common_values_for_fields common_fields
        add_behaviours
      end

      form_name 'packing_specification_item'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      form_object_merge!(@setup_repo.find_product_setup(@form_object.product_setup_id))
      form_object_merge!(@repo.extend_packing_specification(@form_object))
      @form_object.to_h.each_key do |k|
        fields[k] = { renderer: :label }
      end

      fields[:packed_tm_group] = { renderer: :label, caption: 'Packed TM Group' }
      fields[:pallet_label_name] = { renderer: :label, caption: 'Pallet Label' }
      fields[:pm_bom] = { renderer: :label,  caption: 'PKG BOM' }
      fields[:pm_mark] = { renderer: :label,  caption: 'PKG Mark' }
      fields[:tu_labour_product] = { renderer: :label, caption: 'TU Labour Product' }
      fields[:ru_labour_product] = { renderer: :label, caption: 'RU Labour Product' }
      fields[:ri_labour_product] = { renderer: :label, caption: 'RI Labour Product' }
      fields[:fruit_stickers] = { renderer: :label, caption: 'Fruit Stickers' }
      fields[:tu_stickers] = { renderer: :label, caption: 'TU Stickers' }
      fields[:ru_stickers] = { renderer: :label, caption: 'RU Stickers' }
      fields[:rebin] = { renderer: :label, as_boolean: true }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      {
        product_setup_template_id: { renderer: :select,
                                     caption: 'Product Setup Template',
                                     options: @setup_repo.for_select_product_setup_templates,
                                     disabled_options: @setup_repo.for_select_inactive_product_setup_templates,
                                     prompt: true,
                                     required: true,
                                     hide_on_load: @mode == :edit },
        product_setup: { renderer: :label,
                         caption: 'Product Setup',
                         hide_on_load: @mode == :new },
        product_setup_id: { renderer: :select,
                            caption: 'Product Setup',
                            options: @setup_repo.for_select_product_setups(
                              where: { product_setup_template_id: @form_object.product_setup_template_id }
                            ),
                            disabled_options: @setup_repo.for_select_inactive_product_setups,
                            prompt: true,
                            required: true,
                            hide_on_load: @mode == :edit },
        description: {},
        pm_bom_id: { renderer: :select,
                     caption: 'PKG BOM',
                     options: @bom_repo.for_select_packing_spec_pm_boms(
                       where: { std_fruit_size_count_id: @form_object.std_fruit_size_count_id,
                                basic_pack_id: @form_object.basic_pack_id }
                     ),
                     disabled_options: @bom_repo.for_select_inactive_pm_boms,
                     searchable: true,
                     prompt: true,
                     required: false },
        pm_mark_id: { renderer: :select,
                      caption: 'PKG Mark',
                      options: @bom_repo.for_select_pm_marks(
                        where: { mark_id: @form_object.mark_id }
                      ),
                      disabled_options: @bom_repo.for_select_inactive_pm_marks,
                      searchable: true,
                      prompt: true,
                      required: false },
        tu_labour_product_id: { renderer: :select,
                                caption: 'TU Labour Product',
                                options: @bom_repo.for_select_pm_products(
                                  where: { subtype_code: AppConst::PM_SUBTYPE_TU_LABOUR }
                                ),
                                disabled_options: @bom_repo.for_select_inactive_pm_products,
                                prompt: true,
                                required: false },
        ru_labour_product_id: { renderer: :select,
                                caption: 'RU Labour Product',
                                options: @bom_repo.for_select_pm_products(
                                  where: { subtype_code: AppConst::PM_SUBTYPE_RU_LABOUR }
                                ),
                                disabled_options: @bom_repo.for_select_inactive_pm_products,
                                prompt: true,
                                required: false },
        ri_labour_product_id: { renderer: :select,
                                caption: 'RI Labour Product',
                                options: @bom_repo.for_select_pm_products(
                                  where: { subtype_code: AppConst::PM_SUBTYPE_RI_LABOUR }
                                ),
                                disabled_options: @bom_repo.for_select_inactive_pm_products,
                                prompt: true,
                                required: false },
        fruit_sticker_ids: { renderer: :multi,
                             caption: 'Fruit Stickers',
                             options: @bom_repo.for_select_pm_products(
                               where: { pm_type_code: AppConst::PM_TYPE_STICKER }
                             ),
                             selected: @form_object.fruit_sticker_ids,
                             required: false },
        tu_sticker_ids: { renderer: :multi,
                          caption: 'TU Stickers',
                          options: @bom_repo.for_select_pm_products(
                            where: { subtype_code: AppConst::PM_SUBTYPE_TU_STICKER }
                          ),
                          selected: @form_object.tu_sticker_ids,
                          required: false },
        ru_sticker_ids: { renderer: :multi,
                          caption: 'RU Stickers',
                          options: @bom_repo.for_select_pm_products(
                            where: { subtype_code: AppConst::PM_SUBTYPE_RU_STICKER }
                          ),
                          selected: @form_object.ru_sticker_ids,
                          required: false }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      form_object_merge!(@repo.find_packing_specification_item(@options[:id]))
    end

    def make_new_form_object
      @form_object = OpenStruct.new(product_setup_template_id: nil,
                                    description: nil,
                                    pm_bom_id: nil,
                                    pm_mark_id: nil,
                                    mark_id: nil,
                                    product_setup_id: nil,
                                    std_fruit_size_count_id: nil,
                                    basic_pack_code_id: nil,
                                    tu_labour_product_id: nil,
                                    ru_labour_product_id: nil,
                                    fruit_sticker_ids: nil,
                                    tu_sticker_ids: nil,
                                    ru_sticker_ids: nil)
    end

    private

    def add_behaviours
      url = '/production/packing_specifications/packing_specification_items'
      behaviours do |behaviour|
        behaviour.dropdown_change :product_setup_template_id,
                                  notify: [{ url: "#{url}/product_setup_template_changed" }]
        behaviour.dropdown_change :product_setup_id,
                                  notify: [{ url: "#{url}/product_setup_changed" }]
      end
    end
  end
end
