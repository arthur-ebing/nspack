# frozen_string_literal: true

module UiRules
  class OrchardTestResultRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules # rubocop:disable Metrics/AbcSize
      @repo = QualityApp::OrchardTestRepo.new
      @cultivar_repo = MasterfilesApp::CultivarRepo.new
      @farm_repo = MasterfilesApp::FarmRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields new_fields if @mode == :new
      common_values_for_fields edit_fields if @mode == :edit
      common_values_for_fields bulk_edit_fields if @mode == :bulk_edit

      set_show_fields if %i[show reopen].include? @mode
      add_behaviours if %i[new edit bulk_edit].include? @mode

      form_name 'orchard_test_result'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:orchard_test_type_id] = { renderer: :label,
                                        with_value: @form_object.orchard_test_type_code,
                                        caption: 'Orchard Test Type' }
      fields[:puc_id] = { renderer: :label,
                          with_value: @form_object.puc_code,
                          caption: 'Puc',
                          required: true }
      fields[:orchard_id] = { renderer: :label,
                              with_value: @form_object.orchard_code,
                              caption: 'Orchard',
                              required: true }
      fields[:cultivar_id] = { renderer: :label,
                               with_value: @form_object.cultivar_code,
                               caption: 'Cultivars',
                               required: true }
      fields[:passed] = { renderer: :label,
                          with_value: @form_object.passed ? 'Passed' : 'Failed',
                          caption: 'Result' }
      fields[:classification] = { renderer: :label, as_boolean: true }
      fields[:freeze_result] = { renderer: :label, as_boolean: true }
      fields[:api_result] = { renderer: :label }
      fields[:result] = { renderer: :label }

      fields[:applicable_from] = { renderer: :label }
      fields[:applicable_to] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def new_fields # rubocop:disable Metrics/AbcSize
      orchard = @farm_repo.find_orchard(@form_object.orchard_id)
      puc_ids = @repo.select_values(:orchards, :puc_id).uniq
      {
        orchard_test_type_id: { renderer: :select,
                                options: @repo.for_select_orchard_test_types,
                                disabled_options: @repo.for_select_inactive_orchard_test_types,
                                caption: 'Orchard Test Type',
                                required: true,
                                prompt: true },
        puc_id: { renderer: :select,
                  options: @farm_repo.for_select_pucs(where: { id: puc_ids }),
                  disabled_options: @farm_repo.for_select_inactive_pucs,
                  caption: 'Puc',
                  required: true,
                  prompt: true },
        orchard_id: { renderer: :select,
                      options: @repo.for_select_orchards(where: { puc_id: @form_object.puc_id }),
                      disabled_options: @repo.for_select_inactive_orchards,
                      caption: 'Orchard',
                      required: true,
                      prompt: true },
        cultivar_id: { renderer: :select,
                       options: @repo.for_select_cultivar_codes(where: { id: Array(orchard&.cultivar_ids) }),
                       disabled_options: @repo.for_select_inactive_cultivar_codes,
                       caption: 'Cultivar',
                       required: true }
      }
    end

    def edit_fields
      {
        orchard_test_type_id: { renderer: :label,
                                with_value: @form_object.orchard_test_type_code,
                                caption: 'Orchard Test Type' },
        puc_id: { renderer: :label,
                  with_value: @form_object.puc_code,
                  caption: 'Puc' },
        orchard_id: { renderer: :label,
                      with_value: @form_object.orchard_code,
                      caption: 'Orchard' },
        cultivar_id: { renderer: :label,
                       with_value: @form_object.cultivar_code,
                       caption: 'Cultivar' },
        passed: { renderer: :label,
                  with_value: @form_object.passed ? 'Passed' : 'Failed',
                  caption: 'Result',
                  hide_on_load: @classification },
        api_result: { caption: 'Result' },
        api_pass_result: { renderer: :label,
                           caption: 'Pass Result' },
        classification: { renderer: :label,
                          as_boolean: true,
                          hide_on_load: !@classification },
        freeze_result: { renderer: :checkbox,
                         hide_on_load: false },
        api_response: { hide_on_load: false },
        applicable_from: { renderer: :date },
        applicable_to: { renderer: :date }
      }
    end

    def bulk_edit_fields
      {
        orchard_test_type_id: { renderer: :label,
                                with_value: @form_object.orchard_test_type_code,
                                caption: 'Orchard Test Type' },
        update_all: { renderer: :checkbox },
        group_ids: { renderer: :multi,
                     options: @repo.for_select_orchard_test_results(@form_object.orchard_test_type_id),
                     caption: 'Puc / Orchard / Cultivar' },
        passed: { renderer: :label,
                  with_value: @form_object.passed ? 'Passed' : 'Failed',
                  caption: 'Result',
                  hide_on_load: @classification },
        api_result: { caption: 'Result' },
        classification: { renderer: :checkbox,
                          hide_on_load: !@classification },
        freeze_result: { renderer: :checkbox,
                         hide_on_load: false },
        api_response: { hide_on_load: false },
        applicable_from: { renderer: :date },
        applicable_to: { renderer: :date }
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
        behaviour.dropdown_change :puc_id, notify: [{ url: '/quality/test_results/orchard_test_results/puc_changed' }]
        behaviour.dropdown_change :puc_ids, notify: [{ url: '/quality/test_results/orchard_test_results/pucs_changed' }]
        behaviour.dropdown_change :orchard_id, notify: [{ url: '/quality/test_results/orchard_test_results/orchard_changed' }]
        behaviour.dropdown_change :orchard_ids, notify: [{ url: '/quality/test_results/orchard_test_results/orchards_changed' }]
        behaviour.input_change :update_all, notify: [{ url: '/quality/test_results/orchard_test_results/bulk_edit_all' }]
      end
    end
  end
end
