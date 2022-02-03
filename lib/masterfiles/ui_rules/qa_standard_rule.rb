# frozen_string_literal: true

module UiRules
  class QaStandardRule < Base
    def generate_rules
      puts '>>>>>  generate_rules  <<<<<<<'
      @repo = MasterfilesApp::QaStandardRepo.new
      @tm_repo = MasterfilesApp::TargetMarketRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      # set_complete_fields if @mode == :complete
      # set_approve_fields if @mode == :approve

      # add_approve_behaviours if @mode == :approve

      add_behaviours if %i[new edit].include? @mode

      form_name 'qa_standard'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      season_id_label = @repo.get(:seasons, @form_object.season_id, :season_code)
      qa_standard_type_id_label = @repo.get(:qa_standard_types, @form_object.qa_standard_type_id, :qa_standard_type_code)
      fields[:qa_standard_name] = { renderer: :label, caption: 'QA Standard Name' }
      fields[:description] = { renderer: :label }
      fields[:season_id] = { renderer: :label, with_value: season_id_label, caption: 'Season' }
      fields[:qa_standard_type_id] = { renderer: :label, with_value: qa_standard_type_id_label, caption: 'QA Standard Type' }
      fields[:target_market_ids] = { renderer: :label }
      fields[:packed_tm_group_ids] = { renderer: :label, caption: 'Packed TM Group IDs' }
      fields[:internal_standard] = { renderer: :label, as_boolean: true }
      fields[:applies_to_all_markets] = { renderer: :label, as_boolean: true }
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
    #   fields[:to] = { renderer: :select, options: user_repo.email_addresses(user_email_group: AppConst::EMAIL_GROUP_QA_STANDARD_APPROVERS), caption: 'Email address of person to notify', required: true }
    # end

    def common_fields
      puts '>>>>>  common_fields  <<<<<<<'
      {
        qa_standard_name: { required: true, caption: 'QA Standard Name' },
        description: {},
        season_id: { renderer: :select, options: MasterfilesApp::CalendarRepo.new.for_select_seasons, disabled_options: MasterfilesApp::CalendarRepo.new.for_select_inactive_seasons, caption: 'Season', required: true },
        qa_standard_type_id: { renderer: :select, options: MasterfilesApp::QaStandardTypeRepo.new.for_select_qa_standard_types, disabled_options: MasterfilesApp::QaStandardTypeRepo.new.for_select_inactive_qa_standard_types, caption: 'QA Standard Type', required: true },
        # packed_tm_group_ids: { caption: 'Packed TM Group IDs' },
        packed_tm_group_ids: { renderer: :multi, options: @tm_repo.for_select_packed_tm_groups, selected: @form_object.packed_tm_group_ids, caption: 'Packed TM Group IDs' },
        # target_market_ids: {},
        target_market_ids: { renderer: :multi, options: @tm_repo.for_select_packed_group_tms, selected: @form_object.target_market_ids, caption: 'Target Market IDs' },
        internal_standard: { renderer: :checkbox },
        applies_to_all_markets: { renderer: :checkbox }
      }
    end

    def make_form_object
      puts '>>>>>  make_form_object  <<<<<<<'
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_qa_standard(@options[:id])
    end

    def make_new_form_object
      puts '>>>>>  make_new_form_object  <<<<<<<'
      @form_object = new_form_object_from_struct(MasterfilesApp::QaStandard)
      # @form_object = new_form_object_from_struct(MasterfilesApp::QaStandard, merge_hash: { some_column: 'some value' })
      # @form_object = OpenStruct.new(qa_standard_name: nil,
      #                               description: nil,
      #                               season_id: nil,
      #                               qa_standard_type_id: nil,
      #                               target_market_ids: nil,
      #                               packed_tm_group_ids: nil,
      #                               internal_standard: nil,
      #                               applies_to_all_markets: nil)
    end

    def handle_behaviour
      puts ">>>>>  handle_behaviour (#{@mode}) <<<<<<<"
      case @mode
      when :applies_to_all_markets
        applies_to_all_markets_change
      when :packed_tm_group_ids
        packed_tm_group_ids_change
      when :qa_standard_name
        qa_standard_name_change
      else
        unhandled_behaviour!
      end
    end

    private

    def add_behaviours
      puts '>>>>>  add_behaviours  <<<<<<<'
      url = "/masterfiles/quality/qa_standards/change/#{@mode}"
      # url = "/masterfiles/quality/qa_standards/change"
      behaviours do |behaviour|
        behaviour.input_change :applies_to_all_markets, notify: [{ url: "#{url}/applies_to_all_markets" }]
        behaviour.lose_focus :packed_tm_group_ids, notify: [{ url: "#{url}/packed_tm_group_ids" }]
        # behaviour.input_change :packed_tm_group_ids, notify: [{ url: "#{url}/packed_tm_group_ids" }]
        behaviour.lose_focus :qa_standard_name, notify: [{ url: "#{url}/qa_standard_name" }]
      end
    end

    def applies_to_all_markets_change
      puts ">>>>>  applies_to_all_markets_change (#{params[:changed_value]})  <<<<<<<"
      actions = []
      actions << OpenStruct.new(type: params[:changed_value] == 'f' ? :show_element : :hide_element,
                                dom_id: 'qa_standard_target_market_ids_field_wrapper')
      actions << OpenStruct.new(type: params[:changed_value] == 'f' ? :show_element : :hide_element,
                                dom_id: 'qa_standard_packed_tm_group_ids_field_wrapper')
      actions << OpenStruct.new(type: :replace_input_value, dom_id: 'qa_standard_target_market_ids', value: [])
      json_actions(actions)
    end

    def packed_tm_group_ids_change
      puts ">>>>>  packed_tm_group_ids_change (#{params[:changed_value]})  <<<<<<<"
      actions = []
      # actions << OpenStruct.new(type: params[:changed_value] == 'f' ? :show_element : :hide_element,
      #                           dom_id: 'qa_standard_target_market_ids_field_wrapper')
      # actions << OpenStruct.new(type: params[:changed_value] == 'f' ? :show_element : :hide_element,
      #                           dom_id: 'qa_standard_packed_tm_group_ids_field_wrapper')
      # actions << OpenStruct.new(type: :replace_input_value, dom_id: 'qa_standard_target_market_ids', value: [])
      json_actions(actions)
    end

    def qa_standard_name_change
      puts ">>>>>  qa_standard_name_change (#{params[:changed_value]})  <<<<<<<"
      actions = []
      json_actions(actions)
    end

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
    #   json_replace_select_options('qa_standard_an_id', sel)
    # end
  end
end
