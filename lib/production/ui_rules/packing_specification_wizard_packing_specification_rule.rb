# frozen_string_literal: true

module UiRules
  class PackingSpecificationWizardPackingSpecificationRule < Base
    def generate_rules
      form_name 'packing_specification_wizard'

      common_values_for_fields common_fields
      make_header_table
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      make_form_object
      {
        pm_bom_id: { renderer: :select,
                     caption: 'PKG BOM',
                     options: @bom_repo.for_select_packing_spec_pm_boms(
                       where: { std_fruit_size_count_id: @form_object.std_fruit_size_count_id,
                                basic_pack_id: @form_object.basic_pack_code_id }
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
                               where: { subtype_code: AppConst::PM_SUBTYPE_FRUIT_STICKER }
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
      @repo = ProductionApp::PackingSpecificationRepo.new
      @bom_repo = MasterfilesApp::BomRepo.new
      apply_form_values
    end

    def make_header_table
      form_object_merge!(@repo.extend_packing_specification(@form_object))
      compact_header(UtilityFunctions.symbolize_keys(@form_object.compact_header))
    end
  end
end
