# frozen_string_literal: true

module UiRules
  class OrchardTestResultRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @repo = QualityApp::OrchardTestRepo.new
      @cultivar_repo = MasterfilesApp::CultivarRepo.new
      @farm_repo = MasterfilesApp::FarmRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      add_behaviours if %i[new edit].include? @mode
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
      fields[:description] = { renderer: :label }
      fields[:passed] = { renderer: :label,
                          with_value: @form_object.passed ? 'Passed' : 'Failed',
                          caption: 'Result' }
      fields[:classification_only] = { renderer: :label, as_boolean: true }
      fields[:freeze_result] = { renderer: :label, as_boolean: true }
      fields[:api_result] = { renderer: :label }
      fields[:classification] = { renderer: :label }

      fields[:applicable_from] = { renderer: :label }
      fields[:applicable_to] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      orchard = @farm_repo.find_orchard(@form_object.orchard_id)
      edit_orchard_test_type_renderer = { renderer: :select,
                                          options: @repo.for_select_orchard_test_types,
                                          disabled_options: @repo.for_select_inactive_orchard_test_types,
                                          caption: 'Orchard Test Type',
                                          required: true,
                                          prompt: true }
      show_orchard_test_type_renderer = { renderer: :label,
                                          with_value: @form_object.orchard_test_type_code,
                                          caption: 'Orchard Test Type' }
      {
        orchard_test_type_id: @mode == :new ? edit_orchard_test_type_renderer : show_orchard_test_type_renderer,
        puc_id: { renderer: :select,
                  options: @farm_repo.for_select_pucs,
                  disabled_options: @farm_repo.for_select_inactive_pucs,
                  caption: 'Puc',
                  required: true,
                  prompt: true },
        puc_ids: { renderer: :multi,
                   options: @farm_repo.for_select_pucs,
                   selected: [@form_object.puc_id],
                   caption: 'Pucs',
                   required: true },
        orchard_id: { renderer: :select,
                      options: @repo.for_select_orchards(where: { puc_id: @form_object.puc_id }),
                      disabled_options: @repo.for_select_inactive_orchards,
                      caption: 'Orchard',
                      required: true,
                      prompt: true },
        orchard_ids: { renderer: :multi,
                       options: @repo.for_select_orchards(where: { puc_id: @form_object.puc_id }),
                       selected: [@form_object.orchard_id],
                       caption: 'Orchards',
                       required: true },
        cultivar_id: { renderer: :select,
                       options: @repo.for_select_cultivars(where: { id: Array(orchard&.cultivar_ids) }),
                       disabled_options: @repo.for_select_inactive_cultivars,
                       caption: 'Cultivar',
                       required: true },
        cultivar_ids: { renderer: :multi,
                        options: @repo.for_select_cultivars(where: { id: Array(orchard&.cultivar_ids) }),
                        selected: [@form_object.cultivar_id],
                        caption: 'Cultivars',
                        required: true },
        description: { hide_on_load: false },
        passed: { renderer: :select,
                  options: [%w[Failed false], %w[Passed true]],
                  caption: 'Result',
                  hide_on_load: !@pass_fail },
        classification: { hide_on_load: @pass_fail },
        classification_only: { renderer: :checkbox,
                               hide_on_load: @pass_fail },
        freeze_result: { renderer: :checkbox,
                         hide_on_load: false },
        api_result: { hide_on_load: false },
        applicable_from: { renderer: :date },
        applicable_to: { renderer: :date }
      }
    end

    def make_form_object
      if @mode == :new
        @form_object = OpenStruct.new(orchard_test_type_id: nil)
        return
      end

      @form_object = @repo.find_orchard_test_result_flat(@options[:id])
      @form_object = OpenStruct.new(@form_object.to_h.merge(puc_ids: Array(@form_object.puc_id)))

      @rule_object = @repo.find_orchard_test_type_flat(@form_object[:orchard_test_type_id])
      @pass_fail = @rule_object.result_type == AppConst::PASS_FAIL
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :puc_id, notify: [{ url: '/quality/test_results/orchard_test_results/puc_changed' }]
        behaviour.dropdown_change :puc_ids, notify: [{ url: '/quality/test_results/orchard_test_results/pucs_changed' }]
        behaviour.dropdown_change :orchard_id, notify: [{ url: '/quality/test_results/orchard_test_results/orchard_changed' }]
        behaviour.dropdown_change :orchard_ids, notify: [{ url: '/quality/test_results/orchard_test_results/orchards_changed' }]
      end
    end
  end
end
