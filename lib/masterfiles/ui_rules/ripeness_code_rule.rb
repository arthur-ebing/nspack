# frozen_string_literal: true

module UiRules
  class RipenessCodeRule < Base
    def generate_rules
      @repo = MasterfilesApp::AdvancedClassificationsRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'ripeness_code'
    end

    def set_show_fields
      fields[:ripeness_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:legacy_code] = { renderer: :label }
    end

    def common_fields
      {
        ripeness_code: { required: true },
        description: {},
        legacy_code: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_ripeness_code(@options[:id])
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(MasterfilesApp::RipenessCode)
      # @form_object = new_form_object_from_struct(MasterfilesApp::RipenessCode, merge_hash: { some_column: 'some value' })
      # @form_object = OpenStruct.new(ripeness_code: nil,
      #                               description: nil,
      #                               legacy_code: nil)
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
    #   json_replace_select_options('ripeness_code_an_id', sel)
    # end
  end
end
