# frozen_string_literal: true

module UiRules
  class PackingSpecificationRule < Base
    def generate_rules
      @repo = ProductionApp::PackingSpecificationRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'packing_specification'
    end

    def set_show_fields
      fields[:product_setup_template] = { renderer: :label, caption: 'Product Setup Template' }
      fields[:packing_specification_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        product_setup_template_id: { renderer: :select,
                                     options: ProductionApp::ProductSetupRepo.new.for_select_product_setup_templates,
                                     disabled_options: ProductionApp::ProductSetupRepo.new.for_select_inactive_product_setup_templates,
                                     caption: 'Product Setup Template',
                                     required: true },
        packing_specification_code: { required: true },
        description: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_packing_specification(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(product_setup_template_id: nil,
                                    packing_specification_code: nil,
                                    description: nil)
    end
  end
end
