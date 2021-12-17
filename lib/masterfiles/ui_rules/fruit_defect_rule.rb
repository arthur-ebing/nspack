# frozen_string_literal: true

module UiRules
  class FruitDefectRule < Base
    def generate_rules
      @repo = MasterfilesApp::QcRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'fruit_defect'
    end

    def set_show_fields
      rmt_class_id_label = @repo.get(:rmt_classes, @form_object.rmt_class_id, :rmt_class_code)
      fruit_defect_type_id_label = @repo.get(:fruit_defect_types, @form_object.fruit_defect_type_id, :fruit_defect_type_name)
      fields[:rmt_class_id] = { renderer: :label, with_value: rmt_class_id_label, caption: 'Rmt Class' }
      fields[:fruit_defect_type_id] = { renderer: :label, with_value: fruit_defect_type_id_label, caption: 'Fruit Defect Type' }
      fields[:fruit_defect_code] = { renderer: :label }
      fields[:short_description] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:internal] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        rmt_class_id: { renderer: :select,
                        options: MasterfilesApp::FruitRepo.new.for_select_rmt_classes,
                        disabled_options: MasterfilesApp::FruitRepo.new.for_select_inactive_rmt_classes,
                        caption: 'Rmt Class',
                        required: true },
        fruit_defect_type_id: { renderer: :select,
                                options: MasterfilesApp::QcRepo.new.for_select_fruit_defect_types,
                                disabled_options: MasterfilesApp::QcRepo.new.for_select_inactive_fruit_defect_types,
                                caption: 'Fruit Defect Type',
                                required: true },
        fruit_defect_code: { required: true },
        short_description: { required: true },
        description: {},
        internal: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_fruit_defect(@options[:id])
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(MasterfilesApp::FruitDefect)
    end
  end
end
