# frozen_string_literal: true

module UiRules
  class InspectionFailureReasonRule < Base
    def generate_rules
      @repo = MasterfilesApp::InspectionFailureReasonRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      # set_complete_fields if @mode == :complete
      # set_approve_fields if @mode == :approve

      # add_approve_behaviours if @mode == :approve

      form_name 'inspection_failure_reason'
    end

    def set_show_fields
      # inspection_failure_type_id_label = MasterfilesApp::InspectionFailureTypeRepo.new.find_inspection_failure_type(@form_object.inspection_failure_type_id)&.failure_type_code
      inspection_failure_type_id_label = @repo.find(:inspection_failure_types, MasterfilesApp::InspectionFailureType, @form_object.inspection_failure_type_id)&.failure_type_code
      fields[:inspection_failure_type_id] = { renderer: :label, with_value: inspection_failure_type_id_label, caption: 'Inspection Failure Type' }
      fields[:failure_reason] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:main_factor] = { renderer: :label, as_boolean: true }
      fields[:secondary_factor] = { renderer: :label, as_boolean: true }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    # def set_approve_fields
    #   set_show_fields
    #   fields[:approve_action] = { renderer: :select, options: [%w[Approve a], %w[Reject r]], required: true }
    #   fields[:reject_reason] = { renderer: :textarea, disabled: true }
    # end

    # def set_complete_fields
    #   set_show_fields
    #   user_repo = DevelopmentApp::UserRepo.new
    #   fields[:to] = { renderer: :select, options: user_repo.email_addresses(user_email_group: AppConst::EMAIL_GROUP_INSPECTION_FAILURE_REASON_APPROVERS), caption: 'Email address of person to notify', required: true }
    # end

    def common_fields
      {
        inspection_failure_type_id: { renderer: :select, options: MasterfilesApp::InspectionFailureTypeRepo.new.for_select_inspection_failure_types, disabled_options: MasterfilesApp::InspectionFailureTypeRepo.new.for_select_inactive_inspection_failure_types, caption: 'Inspection Failure Type', required: true },
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

    # private

    # def add_approve_behaviours
    #   behaviours do |behaviour|
    #     behaviour.enable :reject_reason, when: :approve_action, changes_to: ['r']
    #   end
    # end
  end
end
