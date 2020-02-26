# frozen_string_literal: true

module UiRules
  class OrchardTestResultRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @repo = QualityApp::OrchardTestRepo.new
      @cultivar_repo = MasterfilesApp::CultivarRepo.new
      @farm_repo = MasterfilesApp::FarmRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields @mode == :new ? new_fields : common_fields

      set_show_fields if %i[show reopen].include? @mode
      add_behaviours if %i[edit].include? @mode
      form_name 'orchard_test_result'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      orchard_set_result_id_label = @repo.find(:orchard_set_results, QualityApp::OrchardSetResult, @form_object.orchard_set_result_id)&.description
      fields[:orchard_test_type_id] = { renderer: :label,
                                        with_value: @form_object.orchard_test_type_code,
                                        caption: 'Orchard Test Type' }
      fields[:orchard_set_result_id] = { renderer: :label,
                                         with_value: orchard_set_result_id_label,
                                         caption: 'Orchard Set Result' }
      fields[:puc_id] = { renderer: :label,
                          with_value: @form_object.puc_code,
                          caption: 'Puc' }
      fields[:orchard_id] = { renderer: :label,
                              with_value: @form_object.orchard_code,
                              caption: 'Orchard' }
      fields[:cultivar_ids] = { renderer: :label,
                                with_value: @form_object.cultivar_codes,
                                caption: 'Cultivars' }

      fields[:description] = { renderer: :label }
      fields[:status_description] = { renderer: :label }
      fields[:passed] = { renderer: :label,
                          with_value: @form_object.passed ? 'Passed' : 'Failed',
                          caption: 'Result' }
      fields[:classification_only] = { renderer: :label, as_boolean: true }
      fields[:freeze_result] = { renderer: :label, as_boolean: true }
      fields[:api_result] = { renderer: :label }
      fields[:classifications] = { renderer: :label }

      fields[:applicable_from] = { renderer: :label }
      fields[:applicable_to] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def new_fields
      {
        orchard_test_type_id: { renderer: :select,
                                options: @repo.for_select_orchard_test_types,
                                disabled_options: @repo.for_select_inactive_orchard_test_types,
                                caption: 'Orchard Test Type',
                                required: true,
                                prompt: true }
      }
    end

    def common_fields
      orchard = @farm_repo.find_orchard(@form_object.orchard_id)
      {
        orchard_test_type_id: { renderer: :label,
                                with_value: @form_object.orchard_test_type_code,
                                caption: 'Orchard Test Type' },
        orchard_set_result_id: { renderer: :select,
                                 hide_on_load: true,
                                 options: @repo.for_select_orchard_set_results,
                                 disabled_options: @repo.for_select_inactive_orchard_set_results,
                                 caption: 'Orchard Set Result' },
        puc_id: { renderer: :select,
                  options: @farm_repo.for_select_pucs,
                  disabled_options: @farm_repo.for_select_inactive_pucs,
                  caption: 'Puc',
                  required: true,
                  prompt: true },
        orchard_id: { renderer: :select,
                      options: @repo.for_select_orchards,
                      disabled_options: @repo.for_select_orchards,
                      caption: 'Orchard',
                      required: @rule_object.applies_to_orchard,
                      prompt: true },
        cultivar_ids: { renderer: :multi,
                        options: @cultivar_repo.for_select_cultivars(where: { id: Array(orchard&.cultivar_ids) }),
                        selected: @form_object.cultivar_ids,
                        caption: 'Cultivars',
                        required: true },
        description: { hide_on_load: true },
        status_description: { hide_on_load: true },
        passed: { renderer: :select,
                  options: [%w[Passed true], %w[Failed false]],
                  caption: 'Result',
                  prompt: true,
                  required: true },
        classification_only: { renderer: :checkbox,
                               hide_on_load: true },
        freeze_result: { renderer: :checkbox,
                         hide_on_load: true },
        api_result: { hide_on_load: true },
        classifications: { hide_on_load: true },
        applicable_from: { renderer: :date,
                           required: true },
        applicable_to: { renderer: :date,
                         required: true }
      }
    end

    def make_form_object
      if @mode == :new
        @form_object = OpenStruct.new(orchard_test_type_id: nil)
        return
      end

      @form_object = @repo.find_orchard_test_result_flat(@options[:id])
      @rule_object = @repo.find_orchard_test_type_flat(@form_object[:orchard_test_type_id])
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :puc_id, notify: [{ url: '/quality/test_results/orchard_test_results/puc_changed' }]
        behaviour.dropdown_change :orchard_id, notify: [{ url: '/quality/test_results/orchard_test_results/orchard_changed' }]
      end
    end
  end
end
