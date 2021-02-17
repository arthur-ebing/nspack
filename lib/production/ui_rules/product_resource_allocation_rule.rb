# frozen_string_literal: true

module UiRules
  class ProductResourceAllocationRule < Base
    def generate_rules
      @repo = ProductionApp::ProductionRunRepo.new
      make_form_object
      apply_form_values

      @rules[:use_packing_specifications] = AppConst::CR_PROD.use_packing_specifications?

      common_values_for_fields common_fields

      form_name 'product_resource_allocation'
    end

    def common_fields
      {
        product_setup_id: { renderer: :select,
                            options: @repo.for_select_product_setups_for_allocation(@options[:id]),
                            prompt: true,
                            invisible: @rules[:use_packing_specifications] },
        packing_specification_item_id: { renderer: :select,
                                         options: @repo.for_select_packing_specification_items_for_allocation(@options[:id]),
                                         prompt: true,
                                         invisible: !@rules[:use_packing_specifications] },
        label_template_id: { renderer: :select,
                             options: MasterfilesApp::LabelTemplateRepo.new.for_select_label_templates(where: { application: AppConst::PRINT_APP_CARTON }),
                             prompt: true,
                             min_charwidth: 50 },
        packing_method_id: { renderer: :select,
                             options: MasterfilesApp::PackagingRepo.new.for_select_packing_methods,
                             required: true }
      }
    end

    def make_form_object
      @form_object = @repo.find_product_resource_allocation(@options[:id])
    end
  end
end
