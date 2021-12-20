# frozen_string_literal: true

module UiRules
  class FruitDefectRule < Base
    def generate_rules
      @repo = MasterfilesApp::QcRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      # set_complete_fields if @mode == :complete
      # set_approve_fields if @mode == :approve

      # add_approve_behaviours if @mode == :approve

      form_name 'fruit_defect'
    end

    def set_show_fields
      # rmt_class_id_label = MasterfilesApp::RmtClassRepo.new.find_rmt_class(@form_object.rmt_class_id)&.rmt_class_code
      # rmt_class_id_label = @repo.find(:rmt_classes, MasterfilesApp::RmtClass, @form_object.rmt_class_id)&.rmt_class_code
      rmt_class_id_label = @repo.get(:rmt_classes, @form_object.rmt_class_id, :rmt_class_code)
      # fruit_defect_type_id_label = MasterfilesApp::FruitDefectTypeRepo.new.find_fruit_defect_type(@form_object.fruit_defect_type_id)&.fruit_defect_type_name
      # fruit_defect_type_id_label = @repo.find(:fruit_defect_types, MasterfilesApp::FruitDefectType, @form_object.fruit_defect_type_id)&.fruit_defect_type_name
      fruit_defect_type_id_label = @repo.get(:fruit_defect_types, @form_object.fruit_defect_type_id, :fruit_defect_type_name)
      fields[:rmt_class_id] = { renderer: :label, with_value: rmt_class_id_label, caption: 'Rmt Class' }
      fields[:fruit_defect_type_id] = { renderer: :label, with_value: fruit_defect_type_id_label, caption: 'Fruit Defect Type' }
      fields[:fruit_defect_code] = { renderer: :label }
      fields[:short_description] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:internal] = { renderer: :label, as_boolean: true }
    end

    # def set_approve_fields
    #   set_show_fields
    #   fields[:approve_action] = { renderer: :select, options: [%w[Approve a], %w[Reject r]], required: true }
    #   fields[:reject_reason] = { renderer: :textarea, disabled: true }
    # end

    # def set_complete_fields
    #   set_show_fields
    #   user_repo = DevelopmentApp::UserRepo.new
    #   fields[:to] = { renderer: :select, options: user_repo.email_addresses(user_email_group: AppConst::EMAIL_GROUP_FRUIT_DEFECT_APPROVERS), caption: 'Email address of person to notify', required: true }
    # end

    def common_fields
      {
        rmt_class_id: { renderer: :select, options: MasterfilesApp::RmtClassRepo.new.for_select_rmt_classes, disabled_options: MasterfilesApp::RmtClassRepo.new.for_select_inactive_rmt_classes, caption: 'Rmt Class', required: true },
        fruit_defect_type_id: { renderer: :select, options: MasterfilesApp::FruitDefectTypeRepo.new.for_select_fruit_defect_types, disabled_options: MasterfilesApp::FruitDefectTypeRepo.new.for_select_inactive_fruit_defect_types, caption: 'Fruit Defect Type', required: true },
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
      # @form_object = new_form_object_from_struct(MasterfilesApp::FruitDefect, merge_hash: { some_column: 'some value' })
      # @form_object = OpenStruct.new(rmt_class_id: nil,
      #                               fruit_defect_type_id: nil,
      #                               fruit_defect_code: nil,
      #                               short_description: nil,
      #                               description: nil,
      #                               internal: nil)
    end

    # def handle_behaviour
    #   case @mode
    #   when :some_change_type
    #     some_change_type_change
    #   else
    #     unhandled_behaviour!
    #   end
    # end

    # private

    # def add_approve_behaviours
    #   behaviours do |behaviour|
    #     behaviour.enable :reject_reason, when: :approve_action, changes_to: ['r']
    #   end
    # end

    # def some_change_type_change
    #   if @params[:changed_value].empty?
    #     sel = []
    #   else
    #     sel = @repo.for_select_somethings(where: { an_id: @params[:changed_value] })
    #   end
    #   json_replace_select_options('fruit_defect_an_id', sel)
    # end
  end
end
