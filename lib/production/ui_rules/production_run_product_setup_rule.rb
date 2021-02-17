# frozen_string_literal: true

module UiRules
  class ProductionRunProductSetupRule < Base
    def generate_rules
      @repo = ProductionApp::ProductSetupRepo.new
      @packing_spec_repo = ProductionApp::PackingSpecificationRepo.new
      @print_repo = LabelApp::PrinterRepo.new
      @template_repo = MasterfilesApp::LabelTemplateRepo.new

      @rules[:use_packing_specifications] = AppConst::CR_PROD.use_packing_specifications?

      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      form_name 'product_setup'
    end

    def common_fields
      {
        product_setup_code: { renderer: :label,
                              invisible: @rules[:use_packing_specifications] },
        packing_specification_item_code: { renderer: :label,
                                           invisible: !@rules[:use_packing_specifications] },
        printer: { renderer: :select,
                   options: @print_repo.select_printers_for_application(AppConst::PRINT_APP_CARTON),
                   required: true,
                   invisible: print_to_robot? },
        no_of_prints: { renderer: :integer, required: true },
        label_template_id: { renderer: :select,
                             options: @template_repo.for_select_label_templates(where: { application: AppConst::PRINT_APP_CARTON }),
                             required: true }
      }
    end

    def make_form_object
      @form_object = if rules[:use_packing_specifications]
                       @packing_spec_repo.find_packing_specification_item(@options[:attrs][:packing_specification_item_id])
                     else
                       @repo.find_product_setup(@options[:attrs][:product_setup_id])
                     end
      @form_object = OpenStruct.new(@form_object.to_h.merge(printer: @print_repo.default_printer_for_application(AppConst::PRINT_APP_CARTON), no_of_prints: 1))
    end

    def print_to_robot?
      @print_repo.print_to_robot?(@options[:request_ip])
    end
  end
end
