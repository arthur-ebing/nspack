# frozen_string_literal: true

module UiRules
  class RmtCodeRule < Base
    def generate_rules
      @repo = MasterfilesApp::RmtCodeRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      # set_complete_fields if @mode == :complete
      # set_approve_fields if @mode == :approve

      # add_approve_behaviours if @mode == :approve

      form_name 'rmt_code'
    end

    def set_show_fields
      # rmt_variant_id_label = MasterfilesApp::RmtVariantRepo.new.find_rmt_variant(@form_object.rmt_variant_id)&.rmt_variant_code
      # rmt_variant_id_label = @repo.find(:rmt_variants, MasterfilesApp::RmtVariant, @form_object.rmt_variant_id)&.rmt_variant_code
      rmt_variant_id_label = @repo.get(:rmt_variants, @form_object.rmt_variant_id, :rmt_variant_code)
      # rmt_handling_regime_id_label = MasterfilesApp::RmtHandlingRegimeRepo.new.find_rmt_handling_regime(@form_object.rmt_handling_regime_id)&.regime_code
      # rmt_handling_regime_id_label = @repo.find(:rmt_handling_regimes, MasterfilesApp::RmtHandlingRegime, @form_object.rmt_handling_regime_id)&.regime_code
      rmt_handling_regime_id_label = @repo.get(:rmt_handling_regimes, @form_object.rmt_handling_regime_id, :regime_code)
      fields[:rmt_variant_id] = { renderer: :label, with_value: rmt_variant_id_label, caption: 'Rmt Variant' }
      fields[:rmt_handling_regime_id] = { renderer: :label, with_value: rmt_handling_regime_id_label, caption: 'Rmt Handling Regime' }
      fields[:rmt_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
    end

    # def set_approve_fields
    #   set_show_fields
    #   fields[:approve_action] = { renderer: :select, options: [%w[Approve a], %w[Reject r]], required: true }
    #   fields[:reject_reason] = { renderer: :textarea, disabled: true }
    # end

    # def set_complete_fields
    #   set_show_fields
    #   user_repo = DevelopmentApp::UserRepo.new
    #   fields[:to] = { renderer: :select, options: user_repo.email_addresses(user_email_group: AppConst::EMAIL_GROUP_RMT_CODE_APPROVERS), caption: 'Email address of person to notify', required: true }
    # end

    def common_fields
      {
        rmt_variant_id: { renderer: :select, options: MasterfilesApp::RmtVariantRepo.new.for_select_rmt_variants, caption: 'Rmt Variant', required: true },
        rmt_handling_regime_id: { renderer: :select, options: MasterfilesApp::RmtHandlingRegimeRepo.new.for_select_rmt_handling_regimes, caption: 'Rmt Handling Regime', required: true },
        rmt_code: { required: true },
        description: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_rmt_code(@options[:id])
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(MasterfilesApp::RmtCode)
      # @form_object = new_form_object_from_struct(MasterfilesApp::RmtCode, merge_hash: { some_column: 'some value' })
      # @form_object = OpenStruct.new(rmt_variant_id: nil,
      #                               rmt_handling_regime_id: nil,
      #                               rmt_code: nil,
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
    #   json_replace_select_options('rmt_code_an_id', sel)
    # end
  end
end
