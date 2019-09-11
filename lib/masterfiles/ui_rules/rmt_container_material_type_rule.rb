# frozen_string_literal: true

module UiRules
  class RmtContainerMaterialTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::RmtContainerMaterialTypeRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      # set_complete_fields if @mode == :complete
      # set_approve_fields if @mode == :approve

      # add_approve_behaviours if @mode == :approve

      form_name 'rmt_container_material_type'
    end

    def set_show_fields
      # rmt_container_type_id_label = MasterfilesApp::RmtContainerTypeRepo.new.find_rmt_container_type(@form_object.rmt_container_type_id)&.container_type_code
      rmt_container_type_id_label = @repo.find(:rmt_container_types, MasterfilesApp::RmtContainerType, @form_object.rmt_container_type_id)&.container_type_code
      fields[:rmt_container_type_id] = { renderer: :label, with_value: rmt_container_type_id_label, caption: 'Rmt Container Type' }
      fields[:container_material_type_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:tare_weight] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:container_material_owners] = { renderer: :list, caption: 'Container Owners', items: @form_object.container_material_owners }
    end

    # def set_approve_fields
    #   set_show_fields
    #   fields[:approve_action] = { renderer: :select, options: [%w[Approve a], %w[Reject r]], required: true }
    #   fields[:reject_reason] = { renderer: :textarea, disabled: true }
    # end

    # def set_complete_fields
    #   set_show_fields
    #   user_repo = DevelopmentApp::UserRepo.new
    #   fields[:to] = { renderer: :select, options: user_repo.email_addresses(user_email_group: AppConst::EMAIL_GROUP_RMT_CONTAINER_MATERIAL_TYPE_APPROVERS), caption: 'Email address of person to notify', required: true }
    # end

    def common_fields
      {
        rmt_container_type_id: { renderer: :select, options: MasterfilesApp::RmtContainerTypeRepo.new.for_select_rmt_container_types, disabled_options: MasterfilesApp::RmtContainerTypeRepo.new.for_select_inactive_rmt_container_types, caption: 'rmt_container_type', required: true },
        container_material_type_code: { required: true },
        description: {},
        tare_weight: {},
        party_role_ids: { renderer: :multi, options: @repo.for_select_party_roles, caption: 'Container Owners', selected: @form_object.party_role_ids, required: false  }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_rmt_container_material_type(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(rmt_container_type_id: nil,
                                    container_material_type_code: nil,
                                    description: nil,
                                    tare_weight: nil,
                                    party_role_ids: [])
    end

    # private

    # def add_approve_behaviours
    #   behaviours do |behaviour|
    #     behaviour.enable :reject_reason, when: :approve_action, changes_to: ['r']
    #   end
    # end
  end
end
