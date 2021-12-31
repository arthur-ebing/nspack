# frozen_string_literal: true

module UiRules
  class FruitDefectTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::QcRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'fruit_defect_type'
    end

    def set_show_fields
      fields[:fruit_defect_category_id] = { renderer: :label, with_value: fruit_defect_category_id_label, caption: 'Fruit Defect Category' }
      fields[:fruit_defect_type_name] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:reporting_description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        fruit_defect_category_id: { renderer: :select,
                                    options: @repo.for_select_fruit_defect_categories,
                                    disabled_options: @repo.for_select_inactive_fruit_defect_categories,
                                    caption: 'Fruit Defect Category' },
        fruit_defect_type_name: { required: true },
        description: {},
        reporting_description: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_fruit_defect_type(@options[:id])
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(MasterfilesApp::FruitDefectType)
    end

    def fruit_defect_category_id_label
      @repo.get(:fruit_defect_categories, :defect_category, @form_object.fruit_defect_category_id)
    end
  end
end
