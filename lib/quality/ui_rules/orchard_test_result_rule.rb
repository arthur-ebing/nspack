# frozen_string_literal: true

module UiRules
  class OrchardTestResultRule < Base
    def generate_rules # rubocop:disable Metrics/AbcSize
      @repo = QualityApp::OrchardTestRepo.new
      @cultivar_repo = MasterfilesApp::CultivarRepo.new
      @farm_repo = MasterfilesApp::FarmRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields new_fields if @mode == :new
      common_values_for_fields edit_fields if @mode == :edit
      common_values_for_fields bulk_edit_fields if @mode == :bulk_edit

      set_show_fields if %i[show].include? @mode
      add_behaviours if %i[new edit bulk_edit].include? @mode

      form_name 'orchard_test_result'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:orchard_test_type_id] = { renderer: :label,
                                        with_value: @form_object.orchard_test_type_code,
                                        caption: 'Test Type' }
      fields[:puc_id] = { renderer: :label,
                          with_value: @form_object.puc_code,
                          caption: 'PUC',
                          required: true }
      fields[:orchard_id] = { renderer: :label,
                              with_value: @form_object.orchard_code,
                              caption: 'Orchard',
                              required: true }
      fields[:cultivar_id] = { renderer: :label,
                               with_value: @form_object.cultivar_code,
                               caption: 'Cultivars',
                               required: true }
      fields[:api_result] = { renderer: :label,
                              caption: @classification ? 'Classification' : 'Result' }
      fields[:api_pass_result] = { renderer: :label }

      fields[:passed] = { renderer: :label,
                          with_value: @form_object.passed ? 'Passed' : 'Failed',
                          caption: 'Result' }
      fields[:classification] = { renderer: :label, as_boolean: true }
      fields[:freeze_result] = { renderer: :label, as_boolean: true }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def new_fields
      puc_ids = @repo.select_values(:orchards, :puc_id).uniq
      {
        orchard_test_type_id: { renderer: :select,
                                options: @repo.for_select_orchard_test_types,
                                disabled_options: @repo.for_select_inactive_orchard_test_types,
                                caption: 'Test Type',
                                required: true,
                                prompt: true },
        puc_id: { renderer: :select,
                  options: @farm_repo.for_select_pucs(where: { id: puc_ids }),
                  disabled_options: @farm_repo.for_select_inactive_pucs,
                  caption: 'PUC',
                  required: true,
                  prompt: true }
      }
    end

    def edit_fields
      {
        orchard_test_type_id: { renderer: :label,
                                with_value: @form_object.orchard_test_type_code,
                                caption: 'Test Type' },
        puc_id: { renderer: :label,
                  with_value: @form_object.puc_code,
                  caption: 'PUC' },
        orchard_id: { renderer: :label,
                      with_value: @form_object.orchard_code,
                      caption: 'Orchard' },
        cultivar_id: { renderer: :label,
                       with_value: @form_object.cultivar_code,
                       caption: 'Cultivar' },
        passed: { renderer: :label,
                  with_value: @form_object.passed ? 'Passed' : 'Failed',
                  caption: 'Test Result',
                  hide_on_load: @classification },
        api_result: { caption: @classification ? 'Classification' : 'Result' },
        api_pass_result: { renderer: :label,
                           hide_on_load: @classification,
                           caption: 'Pass Result' },
        classification: { renderer: :label,
                          as_boolean: true,
                          hide_on_load: !@classification },
        freeze_result: { renderer: :checkbox,
                         hide_on_load: false },
        api_response: { hide_on_load: false }
      }
    end

    def bulk_edit_fields
      {
        orchard_test_type_id: { renderer: :label,
                                with_value: @form_object.orchard_test_type_code,
                                caption: 'Test Type' },
        update_all: { renderer: :checkbox },
        group_ids: { renderer: :multi,
                     options: @repo.for_select_orchard_test_results(@form_object.orchard_test_type_id),
                     caption: 'PUC / Orchard / Cultivar' },
        passed: { renderer: :label,
                  with_value: @form_object.passed ? 'Passed' : 'Failed',
                  caption: 'Result',
                  hide_on_load: @classification },
        api_result: { caption: 'Result' },
        api_pass_result: { renderer: :label,
                           hide_on_load: @classification,
                           caption: 'Pass Result' },
        classification: { renderer: :label,
                          as_boolean: true,
                          hide_on_load: !@classification },
        freeze_result: { renderer: :checkbox,
                         hide_on_load: false },
        api_response: { hide_on_load: false }
      }
    end

    def make_form_object
      if %i[new].include? @mode
        @form_object = OpenStruct.new(orchard_test_type_id: nil)
        return
      end

      form_object = @repo.find_orchard_test_result_flat(@options[:id]).to_h
      @classification = @repo.get(:orchard_test_types, form_object[:orchard_test_type_id], :result_type) == AppConst::CLASSIFICATION
      form_object[:puc_ids] = Array(form_object[:puc_id])
      form_object[:classification] = @classification
      form_object[:api_pass_result] = @repo.get(:orchard_test_types, form_object[:orchard_test_type_id], :api_pass_result)
      @form_object = OpenStruct.new(form_object)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.input_change :update_all, notify: [{ url: '/quality/test_results/orchard_test_results/bulk_edit_all' }]
      end
    end
  end
end
