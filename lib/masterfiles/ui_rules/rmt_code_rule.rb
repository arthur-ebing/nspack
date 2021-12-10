# frozen_string_literal: true

module UiRules
  class RmtCodeRule < Base
    def generate_rules
      @repo = MasterfilesApp::AdvancedClassificationsRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

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

    def common_fields
      {
        rmt_handling_regime_id: { renderer: :select, options: @repo.for_select_rmt_handling_regimes, caption: 'Rmt Handling Regime', required: true },
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
    end
  end
end
