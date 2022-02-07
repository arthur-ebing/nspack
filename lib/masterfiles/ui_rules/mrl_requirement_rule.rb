# frozen_string_literal: true

module UiRules
  class MrlRequirementRule < Base
    def generate_rules
      @repo = MasterfilesApp::MrlRequirementRepo.new
      @tm_repo = MasterfilesApp::TargetMarketRepo.new
      @party_repo = MasterfilesApp::PartyRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      # set_complete_fields if @mode == :complete
      # set_approve_fields if @mode == :approve

      # add_approve_behaviours if @mode == :approve

      form_name 'mrl_requirement'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      # season_id_label = MasterfilesApp::SeasonRepo.new.find_season(@form_object.season_id)&.season_code
      # season_id_label = @repo.find(:seasons, MasterfilesApp::Season, @form_object.season_id)&.season_code
      season_id_label = @repo.get(:seasons, :season_code, @form_object.season_id)
      # qa_standard_id_label = MasterfilesApp::QaStandardRepo.new.find_qa_standard(@form_object.qa_standard_id)&.qa_standard_name
      # qa_standard_id_label = @repo.find(:qa_standards, MasterfilesApp::QaStandard, @form_object.qa_standard_id)&.qa_standard_name
      qa_standard_id_label = @repo.get(:qa_standards, :qa_standard_name, @form_object.qa_standard_id)
      # packed_tm_group_id_label = MasterfilesApp::TargetMarketGroupRepo.new.find_target_market_group(@form_object.packed_tm_group_id)&.target_market_group_name
      # packed_tm_group_id_label = @repo.find(:target_market_groups, MasterfilesApp::TargetMarketGroup, @form_object.packed_tm_group_id)&.target_market_group_name
      packed_tm_group_id_label = @repo.get(:target_market_groups, :target_market_group_name, @form_object.packed_tm_group_id)
      # target_market_id_label = MasterfilesApp::TargetMarketRepo.new.find_target_market(@form_object.target_market_id)&.target_market_name
      # target_market_id_label = @repo.find(:target_markets, MasterfilesApp::TargetMarket, @form_object.target_market_id)&.target_market_name
      target_market_id_label = @repo.get(:target_markets, :target_market_name, @form_object.target_market_id)
      # target_customer_id_label = MasterfilesApp::PartyRoleRepo.new.find_party_role(@form_object.target_customer_id)&.id
      # target_customer_id_label = @repo.find(:party_roles, MasterfilesApp::PartyRole, @form_object.target_customer_id)&.id
      target_customer_id_label = @repo.get(:party_roles, :id, @form_object.target_customer_id)
      # cultivar_group_id_label = MasterfilesApp::CultivarGroupRepo.new.find_cultivar_group(@form_object.cultivar_group_id)&.cultivar_group_code
      # cultivar_group_id_label = @repo.find(:cultivar_groups, MasterfilesApp::CultivarGroup, @form_object.cultivar_group_id)&.cultivar_group_code
      cultivar_group_id_label = @repo.get(:cultivar_groups, :cultivar_group_code, @form_object.cultivar_group_id)
      # cultivar_id_label = MasterfilesApp::CultivarRepo.new.find_cultivar(@form_object.cultivar_id)&.cultivar_name
      # cultivar_id_label = @repo.find(:cultivars, MasterfilesApp::Cultivar, @form_object.cultivar_id)&.cultivar_name
      cultivar_id_label = @repo.get(:cultivars, :cultivar_name, @form_object.cultivar_id)
      fields[:season_id] = { renderer: :label, with_value: season_id_label, caption: 'Season' }
      fields[:qa_standard_id] = { renderer: :label, with_value: qa_standard_id_label, caption: 'QA Standard' }
      fields[:packed_tm_group_id] = { renderer: :label, with_value: packed_tm_group_id_label, caption: 'Packed Tm Group' }
      fields[:target_market_id] = { renderer: :label, with_value: target_market_id_label, caption: 'Target Market' }
      fields[:target_customer_id] = { renderer: :label, with_value: target_customer_id_label, caption: 'Target Customer' }
      fields[:cultivar_group_id] = { renderer: :label, with_value: cultivar_group_id_label, caption: 'Cultivar Group' }
      fields[:cultivar_id] = { renderer: :label, with_value: cultivar_id_label, caption: 'Cultivar' }
      fields[:max_num_chemicals_allowed] = { renderer: :label }
      fields[:require_orchard_level_results] = { renderer: :label, as_boolean: true }
      fields[:no_results_equal_failure] = { renderer: :label, as_boolean: true }
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
    #   fields[:to] = { renderer: :select, options: user_repo.email_addresses(user_email_group: AppConst::EMAIL_GROUP_MRL_REQUIREMENT_APPROVERS), caption: 'Email address of person to notify', required: true }
    # end

    def common_fields # rubocop:disable Metrics/AbcSize
      {
        # season_id: { renderer: :select, options: MasterfilesApp::SeasonRepo.new.for_select_seasons, disabled_options: MasterfilesApp::SeasonRepo.new.for_select_inactive_seasons, caption: 'Season', required: true },
        season_id: { renderer: :select, options: MasterfilesApp::CalendarRepo.new.for_select_seasons, disabled_options: MasterfilesApp::CalendarRepo.new.for_select_inactive_seasons, caption: 'Season', required: true },
        qa_standard_id: { renderer: :select, options: MasterfilesApp::QaStandardRepo.new.for_select_qa_standards, disabled_options: MasterfilesApp::QaStandardRepo.new.for_select_inactive_qa_standards, caption: 'QA Standard', prompt: true },
        # packed_tm_group_id: { renderer: :select, options: MasterfilesApp::TargetMarketGroupRepo.new.for_select_target_market_groups, disabled_options: MasterfilesApp::TargetMarketGroupRepo.new.for_select_inactive_target_market_groups, caption: 'Packed Tm Group' },
        packed_tm_group_id: { renderer: :select, options: @tm_repo.for_select_packed_tm_groups, disabled_options: @tm_repo.for_select_inactive_tm_groups, caption: 'Packed TM Group', prompt: true },
        # target_market_id: { renderer: :select, options: MasterfilesApp::TargetMarketRepo.new.for_select_target_markets, disabled_options: MasterfilesApp::TargetMarketRepo.new.for_select_inactive_target_markets, caption: 'Target Market' },
        target_market_id: { renderer: :select, options: @tm_repo.for_select_packed_group_tms, disabled_options: @tm_repo.for_select_inactive_target_markets, caption: 'Target Market', prompt: true },
        # target_customer_id: { renderer: :select, options: MasterfilesApp::PartyRoleRepo.new.for_select_party_roles, disabled_options: MasterfilesApp::PartyRoleRepo.new.for_select_inactive_party_roles, caption: 'Target Customer' },
        target_customer_id: { renderer: :select, options: @party_repo.for_select_party_roles(AppConst::ROLE_TARGET_CUSTOMER), disabled_options: @party_repo.for_select_inactive_party_roles(AppConst::ROLE_TARGET_CUSTOMER), caption: 'Target Customer', prompt: true },
        # cultivar_group_id: { renderer: :select, options: MasterfilesApp::CultivarGroupRepo.new.for_select_cultivar_groups, disabled_options: MasterfilesApp::CultivarGroupRepo.new.for_select_inactive_cultivar_groups, caption: 'Cultivar Group' },
        cultivar_group_id: { renderer: :select, options: MasterfilesApp::CultivarRepo.new.for_select_cultivar_groups, disabled_options: MasterfilesApp::CultivarRepo.new.for_select_inactive_cultivar_groups, caption: 'Cultivar Group', prompt: true },
        cultivar_id: { renderer: :select, options: MasterfilesApp::CultivarRepo.new.for_select_cultivars, disabled_options: MasterfilesApp::CultivarRepo.new.for_select_inactive_cultivars, caption: 'Cultivar', prompt: true },
        max_num_chemicals_allowed: { required: true },
        require_orchard_level_results: { renderer: :checkbox },
        no_results_equal_failure: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_mrl_requirement(@options[:id])
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(MasterfilesApp::MrlRequirement)
      # @form_object = new_form_object_from_struct(MasterfilesApp::MrlRequirement, merge_hash: { some_column: 'some value' })
      # @form_object = OpenStruct.new(season_id: nil,
      #                               qa_standard_id: nil,
      #                               packed_tm_group_id: nil,
      #                               target_market_id: nil,
      #                               target_customer_id: nil,
      #                               cultivar_group_id: nil,
      #                               cultivar_id: nil,
      #                               max_num_chemicals_allowed: nil,
      #                               require_orchard_level_results: nil,
      #                               no_results_equal_failure: nil)
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
    #   json_replace_select_options('mrl_requirement_an_id', sel)
    # end
  end
end
