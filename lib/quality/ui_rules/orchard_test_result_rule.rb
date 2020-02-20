# frozen_string_literal: true

module UiRules
  class OrchardTestResultRule < Base
    def generate_rules
      @repo = QualityApp::OrchardTestRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

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
      fields[:orchard_id] = { renderer: :label,
                              with_value: @form_object.orchard_code,
                              caption: 'Orchard' }
      fields[:puc_id] = { renderer: :label,
                          with_value: @form_object.puc_code,
                          caption: 'Puc' }
      fields[:description] = { renderer: :label }
      fields[:status_description] = { renderer: :label }
      fields[:passed] = { renderer: :label, as_boolean: true }
      fields[:classification_only] = { renderer: :label, as_boolean: true }
      fields[:freeze_result] = { renderer: :label, as_boolean: true }
      fields[:api_result] = { renderer: :label }
      fields[:classifications] = { renderer: :label }
      fields[:cultivar_ids] = { renderer: :label }
      fields[:applicable_from] = { renderer: :label }
      fields[:applicable_to] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      {
        orchard_test_type_id: { renderer: :select,
                                options: QualityApp::OrchardTestRepo.new.for_select_orchard_test_types,
                                disabled_options: QualityApp::OrchardTestRepo.new.for_select_inactive_orchard_test_types,
                                caption: 'Orchard Test Type',
                                required: true },
        orchard_set_result_id: { renderer: :select,
                                 options: QualityApp::OrchardTestRepo.new.for_select_orchard_set_results,
                                 disabled_options: QualityApp::OrchardTestRepo.new.for_select_inactive_orchard_set_results,
                                 caption: 'Orchard Set Result' },
        orchard_id: { renderer: :select,
                      options: MasterfilesApp::FarmRepo.new.for_select_orchards,
                      disabled_options: MasterfilesApp::FarmRepo.new.for_select_inactive_orchards,
                      caption: 'Orchard',
                      required: true },
        puc_id: { renderer: :select,
                  options: MasterfilesApp::FarmRepo.new.for_select_pucs,
                  disabled_options: MasterfilesApp::FarmRepo.new.for_select_inactive_pucs,
                  caption: 'Puc',
                  required: true },
        description: {},
        status_description: {},
        passed: { renderer: :checkbox },
        classification_only: { renderer: :checkbox },
        freeze_result: { renderer: :checkbox },
        api_result: {},
        classifications: {},
        cultivar_ids: { renderer: :multi,
                        options: @repo.for_select_cultivars,
                        selected: @form_object.cultivar_ids,
                        caption: 'Cultivars' },
        applicable_from: { renderer: :date,
                           required: true },
        applicable_to: { renderer: :date,
                         required: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_orchard_test_result_flat(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(orchard_test_type_id: nil,
                                    orchard_set_result_id: nil,
                                    orchard_id: nil,
                                    puc_id: nil,
                                    description: nil,
                                    status_description: nil,
                                    passed: true,
                                    classification_only: true,
                                    freeze_result: true,
                                    api_result: nil,
                                    classifications: nil,
                                    cultivar_ids: nil,
                                    applicable_from: nil,
                                    applicable_to: nil)
    end
  end
end
