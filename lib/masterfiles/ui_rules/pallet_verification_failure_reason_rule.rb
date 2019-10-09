# frozen_string_literal: true

module UiRules
  class PalletVerificationFailureReasonRule < Base
    def generate_rules
      @repo = MasterfilesApp::QualityRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'pallet_verification_failure_reason'
    end

    def set_show_fields
      fields[:reason] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        reason: { required: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_pallet_verification_failure_reason(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(reason: nil)
    end
  end
end
