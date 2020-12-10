# frozen_string_literal: true

module UiRules
  class InspectionFailureReasonRule < Base
    def generate_rules
      @repo = MasterfilesApp::QualityRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'inspection_failure_reason'
    end

    def set_show_fields
      inspection_failure_type_id_label = @repo.find(:inspection_failure_types, MasterfilesApp::InspectionFailureType, @form_object.inspection_failure_type_id)&.failure_type_code
      fields[:inspection_failure_type_id] = { renderer: :label, with_value: inspection_failure_type_id_label, caption: 'Inspection Failure Type' }
      fields[:failure_reason] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:main_factor] = { renderer: :label, as_boolean: true }
      fields[:secondary_factor] = { renderer: :label, as_boolean: true }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        inspection_failure_type_id: { renderer: :select,
                                      options: MasterfilesApp::QualityRepo.new.for_select_inspection_failure_types,
                                      disabled_options: MasterfilesApp::QualityRepo.new.for_select_inactive_inspection_failure_types,
                                      caption: 'Inspection Failure Type',
                                      required: true },
        failure_reason: { required: true },
        description: {},
        main_factor: { renderer: :checkbox },
        secondary_factor: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_inspection_failure_reason(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(inspection_failure_type_id: nil,
                                    failure_reason: nil,
                                    description: nil,
                                    main_factor: nil,
                                    secondary_factor: nil)
    end
  end
end
