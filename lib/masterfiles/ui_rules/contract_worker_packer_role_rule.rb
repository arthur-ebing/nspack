# frozen_string_literal: true

module UiRules
  class ContractWorkerPackerRoleRule < Base
    def generate_rules
      @repo = MasterfilesApp::HumanResourcesRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      # set_complete_fields if @mode == :complete
      # set_approve_fields if @mode == :approve

      # add_approve_behaviours if @mode == :approve

      form_name 'contract_worker_packer_role'
    end

    def set_show_fields
      fields[:packer_role] = { renderer: :label }
      fields[:default_role] = { renderer: :label, as_boolean: true }
      fields[:part_of_group_incentive_target] = { renderer: :label, as_boolean: true }
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
    #   fields[:to] = { renderer: :select, options: user_repo.email_addresses(user_email_group: AppConst::EMAIL_GROUP_CONTRACT_WORKER_PACKER_ROLE_APPROVERS), caption: 'Email address of person to notify', required: true }
    # end

    def common_fields
      {
        packer_role: { required: true },
        default_role: { renderer: :checkbox },
        part_of_group_incentive_target: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_contract_worker_packer_role(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(packer_role: nil,
                                    default_role: nil,
                                    part_of_group_incentive_target: nil)
    end

    # private

    # def add_approve_behaviours
    #   behaviours do |behaviour|
    #     behaviour.enable :reject_reason, when: :approve_action, changes_to: ['r']
    #   end
    # end
  end
end
