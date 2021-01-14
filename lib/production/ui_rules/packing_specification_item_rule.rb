# frozen_string_literal: true

module UiRules
  class PackingSpecificationItemRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @repo = ProductionApp::PackingSpecificationRepo.new
      @bom_repo = MasterfilesApp::BomRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'packing_specification_item'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:packing_specification_code] = { renderer: :label, caption: 'Packing Specification Code' }
      fields[:product_setup] = { renderer: :label,  caption: 'Product Setup' }
      fields[:description] = { renderer: :label }
      fields[:pm_bom] = { renderer: :label,  caption: 'PM BOM' }
      fields[:pm_mark] = { renderer: :label,  caption: 'PM Mark' }
      fields[:tu_labour_product] = { renderer: :label, caption: 'TU Labour Product' }
      fields[:ru_labour_product] = { renderer: :label, caption: 'RU Labour Product' }
      fields[:ri_labour_product] = { renderer: :label, caption: 'RI Labour Product' }
      fields[:fruit_stickers] = { renderer: :label, caption: 'Fruit Stickers' }
      fields[:tu_stickers] = { renderer: :label, caption: 'TU Stickers' }
      fields[:ru_stickers] = { renderer: :label, caption: 'RU Stickers' }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      {
        packing_specification_code: { renderer: :label,
                                      caption: 'Packing Specification Code' },
        product_setup: { renderer: :label,
                         caption: 'Product Setup' },
        description: {},
        packing_specification_id: { renderer: :select,
                                    caption: 'Packing Specification',
                                    options: @repo.for_select_packing_specifications,
                                    disabled_options: @repo.for_select_inactive_packing_specifications,
                                    hide_on_load: true },
        product_setup_id: { renderer: :select,
                            caption: 'Product Setup',
                            options: ProductionApp::ProductSetupRepo.new.for_select_product_setups,
                            disabled_options: ProductionApp::ProductSetupRepo.new.for_select_inactive_product_setups,
                            hide_on_load: true },
        pm_bom_id: { renderer: :select,
                     caption: 'PM BOM',
                     options: @bom_repo.for_select_pm_boms,
                     disabled_options: @bom_repo.for_select_inactive_pm_boms,
                     prompt: true,
                     required: false },
        pm_mark_id: { renderer: :select,
                      caption: 'PM Mark',
                      options: @bom_repo.for_select_pm_marks,
                      disabled_options: @bom_repo.for_select_inactive_pm_marks,
                      prompt: true,
                      required: false },
        tu_labour_product_id: { renderer: :select,
                                caption: 'TU Labour Product',
                                options: @bom_repo.for_select_pm_products(
                                  where: { pm_subtype_id: get_subtype_id('tu') }
                                ),
                                disabled_options: @bom_repo.for_select_inactive_pm_products,
                                prompt: true,
                                required: false },
        ru_labour_product_id: { renderer: :select,
                                caption: 'RU Labour Product',
                                options: @bom_repo.for_select_pm_products(
                                  where: { pm_subtype_id: get_subtype_id('ru') }
                                ),
                                disabled_options: @bom_repo.for_select_inactive_pm_products,
                                prompt: true,
                                required: false },
        ri_labour_product_id: { renderer: :select,
                                caption: 'RI Labour Product',
                                options: @bom_repo.for_select_pm_products(
                                  where: { pm_subtype_id: get_subtype_id('ri') }
                                ),
                                disabled_options: @bom_repo.for_select_inactive_pm_products,
                                prompt: true,
                                required: false },
        fruit_sticker_ids: { renderer: :multi,
                             caption: 'Fruit Stickers',
                             options: @bom_repo.for_select_pm_products(
                               where: { pm_subtype_id: get_subtype_id('fruit_sticker') }
                             ),
                             selected: @form_object.fruit_sticker_ids,
                             required: false },
        tu_sticker_ids: { renderer: :multi,
                          caption: 'TU Stickers',
                          options: @bom_repo.for_select_pm_products(
                            where: { pm_subtype_id: get_subtype_id('tu_sticker') }
                          ),
                          selected: @form_object.tu_sticker_ids,
                          required: false },
        ru_sticker_ids: { renderer: :multi,
                          caption: 'RU Stickers',
                          options: @bom_repo.for_select_pm_products(
                            where: { pm_subtype_id: get_subtype_id('ru_sticker') }
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

      @form_object = @repo.find_packing_specification_item(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(packing_specification_id: nil,
                                    description: nil,
                                    pm_bom_id: nil,
                                    pm_mark_id: nil,
                                    product_setup_id: nil,
                                    tu_labour_product_id: nil,
                                    ru_labour_product_id: nil,
                                    fruit_sticker_ids: nil,
                                    tu_sticker_ids: nil,
                                    ru_sticker_ids: nil)
    end

    private

    def get_subtype_id(subtype_code)
      @repo.get_id(:pm_subtypes, subtype_code: subtype_code)
    end
  end
end
