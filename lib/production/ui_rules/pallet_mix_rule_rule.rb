# frozen_string_literal: true

module UiRules
  class PalletMixRuleRule < Base
    def generate_rules
      @repo = ProductionApp::ProductionRunRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      # set_complete_fields if @mode == :complete
      # set_approve_fields if @mode == :approve

      # add_approve_behaviours if @mode == :approve

      form_name 'pallet_mix_rule'
    end

    def set_show_fields
      fields[:scope] = { renderer: :label }
      fields[:production_run_id] = { renderer: :label }
      fields[:pallet_id] = { renderer: :label }
      fields[:allow_tm_mix] = { renderer: :label, as_boolean: true }
      fields[:allow_grade_mix] = { renderer: :label, as_boolean: true }
      fields[:allow_size_ref_mix] = { renderer: :label, as_boolean: true }
      fields[:allow_pack_mix] = { renderer: :label, as_boolean: true }
      fields[:allow_std_count_mix] = { renderer: :label, as_boolean: true }
      fields[:allow_mark_mix] = { renderer: :label, as_boolean: true }
      fields[:allow_inventory_code_mix] = { renderer: :label, as_boolean: true }
    end

    # def set_approve_fields
    #   set_show_fields
    #   fields[:approve_action] = { renderer: :select, options: [%w[Approve a], %w[Reject r]], required: true }
    #   fields[:reject_reason] = { renderer: :textarea, disabled: true }
    # end

    # def set_complete_fields
    #   set_show_fields
    #   user_repo = DevelopmentApp::UserRepo.new
    #   fields[:to] = { renderer: :select, options: user_repo.email_addresses(user_email_group: AppConst::EMAIL_GROUP_PALLET_MIX_RULE_APPROVERS), caption: 'Email address of person to notify', required: true }
    # end

    def common_fields
      {
        scope: { renderer: :label },
        # production_run_id: {},
        # pallet_id: {},
        allow_tm_mix: { renderer: :checkbox },
        allow_grade_mix: { renderer: :checkbox },
        allow_size_ref_mix: { renderer: :checkbox },
        allow_pack_mix: { renderer: :checkbox },
        allow_std_count_mix: { renderer: :checkbox },
        allow_mark_mix: { renderer: :checkbox },
        allow_inventory_code_mix: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_pallet_mix_rule(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(scope: nil,
                                    production_run_id: nil,
                                    pallet_id: nil,
                                    allow_tm_mix: nil,
                                    allow_grade_mix: nil,
                                    allow_size_ref_mix: nil,
                                    allow_pack_mix: nil,
                                    allow_std_count_mix: nil,
                                    allow_mark_mix: nil,
                                    allow_inventory_code_mix: nil)
    end

    # private

    # def add_approve_behaviours
    #   behaviours do |behaviour|
    #     behaviour.enable :reject_reason, when: :approve_action, changes_to: ['r']
    #   end
    # end
  end
end
