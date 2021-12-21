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

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fruit_defect_type_id_label = @repo.get(:fruit_defect_types, @form_object.fruit_defect_type_id, :fruit_defect_type_name)
      fields[:defect_category] = { renderer: :label }
      fields[:fruit_defect_type_id] = { renderer: :label, with_value: fruit_defect_type_id_label, caption: 'Fruit Defect Type' }
      fields[:fruit_defect_code] = { renderer: :label }
      fields[:short_description] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:internal] = { renderer: :label, as_boolean: true }
      fields[:reporting_description] = { renderer: :label }
      fields[:external] = { renderer: :label, as_boolean: true }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:pre_harvest] = { renderer: :label, as_boolean: true }
      fields[:post_harvest] = { renderer: :label, as_boolean: true }
      fields[:severity] = { renderer: :label }
      fields[:qc_class_2] = { renderer: :label, as_boolean: true }
      fields[:qc_class_3] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        defect_category: { renderer: :label },
        fruit_defect_type_id: { renderer: :select,
                                options: @repo.for_select_fruit_defect_types,
                                disabled_options: @repo.for_select_inactive_fruit_defect_types,
                                caption: 'Fruit Defect Type',
                                required: true },
        fruit_defect_code: { required: true },
        short_description: { required: true },
        description: {},
        reporting_description: {},
        internal: { renderer: :checkbox },
        external: { renderer: :checkbox },
        pre_harvest: { renderer: :checkbox },
        post_harvest: { renderer: :checkbox },
        severity: { renderer: :select, options: AppConst::QC_SEVERITIES, required: true },
        qc_class_2: { renderer: :checkbox },
        qc_class_3: { renderer: :checkbox }
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
      @form_object = new_form_object_from_struct(MasterfilesApp::FruitDefectFlat)
    end
  end
end
