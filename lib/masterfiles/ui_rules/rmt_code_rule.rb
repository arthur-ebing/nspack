# frozen_string_literal: true

module UiRules
  class RmtCodeRule < Base
    def generate_rules
      @repo = MasterfilesApp::AdvancedClassificationsRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      add_behaviours

      form_name 'rmt_code'
    end

    def set_show_fields
      rmt_variant_id_label = @repo.get(:rmt_variants, @form_object.rmt_variant_id, :rmt_variant_code)
      rmt_handling_regime_id_label = @repo.get(:rmt_handling_regimes, @form_object.rmt_handling_regime_id, :regime_code)
      fields[:rmt_variant_id] = { renderer: :label, with_value: rmt_variant_id_label, caption: 'Rmt Variant' }
      fields[:rmt_handling_regime_id] = { renderer: :label, with_value: rmt_handling_regime_id_label, caption: 'Rmt Handling Regime' }
      fields[:rmt_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
    end

    def common_fields
      {
        rmt_variant_id: { renderer: :hidden },
        rmt_handling_regime_id: { renderer: :select, options: @repo.for_select_rmt_handling_regimes,
                                  caption: 'Rmt Handling Regime',
                                  prompt: 'Select Rmt Handling Regime',
                                  required: true },
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
      @form_object = OpenStruct.new(rmt_variant_id: @options[:rmt_variant_id],
                                    rmt_handling_regime_id: nil,
                                    rmt_code: nil,
                                    description: nil)
    end

    def handle_behaviour
      case @mode
      when :handling_regime_changed
        handling_regime_changed
      else
        unhandled_behaviour!
      end
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :rmt_handling_regime_id,
                                  notify: [{ url: '/masterfiles/raw_materials/rmt_codes/ui_change/handling_regime_changed',
                                             param_keys: %i[rmt_code_rmt_variant_id] }]
      end
    end

    def handling_regime_changed
      actions = []
      if @params[:changed_value].empty?
        actions << OpenStruct.new(type: :replace_input_value, dom_id: 'rmt_code_rmt_code', value: nil)
      else
        repo = MasterfilesApp::AdvancedClassificationsRepo.new
        variant_code = repo.get(:rmt_variants, @params[:rmt_code_rmt_variant_id], :rmt_variant_code)
        handling_regime_code = repo.get(:rmt_handling_regimes, @params[:changed_value], :regime_code)
        actions << OpenStruct.new(type: :replace_input_value, dom_id: 'rmt_code_rmt_code', value: variant_code + handling_regime_code)
      end
      json_actions(actions)
    end
  end
end
