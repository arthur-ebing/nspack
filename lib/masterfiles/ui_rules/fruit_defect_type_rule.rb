# frozen_string_literal: true

module UiRules
  class FruitDefectTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::QcRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      # set_complete_fields if @mode == :complete
      # set_approve_fields if @mode == :approve

      # add_approve_behaviours if @mode == :approve

      form_name 'fruit_defect_type'
    end

    def set_show_fields
      fields[:fruit_defect_type_name] = { renderer: :label }
      fields[:description] = { renderer: :label }
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
    #   fields[:to] = { renderer: :select, options: user_repo.email_addresses(user_email_group: AppConst::EMAIL_GROUP_FRUIT_DEFECT_TYPE_APPROVERS), caption: 'Email address of person to notify', required: true }
    # end

    def common_fields
      {
        fruit_defect_type_name: { required: true },
        description: {}
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
      # @form_object = new_form_object_from_struct(MasterfilesApp::FruitDefectType, merge_hash: { some_column: 'some value' })
      # @form_object = OpenStruct.new(fruit_defect_type_name: nil,
      #                               description: nil)
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
    #   json_replace_select_options('fruit_defect_type_an_id', sel)
    # end
  end
end
