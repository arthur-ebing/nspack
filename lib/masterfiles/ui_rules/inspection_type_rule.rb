# frozen_string_literal: true

module UiRules
  class InspectionTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::QualityRepo.new
      make_form_object
      apply_form_values

      add_behaviours

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'inspection_type'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:inspection_type_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:failure_type_code] = { renderer: :label, caption: 'Inspection Failure Type' }
      fields[:passed_default] = { renderer: :label, as_boolean: true }

      fields[:applies_to_all_tm_groups] = { renderer: :label, caption: 'Applies To All TM Groups',
                                            as_boolean: true }
      fields[:applicable_tm_groups] = { renderer: :label, caption: 'Applicable TM Groups',
                                        with_value: @form_object.applicable_tm_groups.join(', ') }

      fields[:applies_to_all_grades] = { renderer: :label, as_boolean: true }
      fields[:applicable_grades] = { renderer: :label, with_value: @form_object.applicable_grades.join(', ') }

      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        inspection_type_code: { required: true },
        description: {},
        inspection_failure_type_id: { renderer: :select, caption: 'Inspection Failure Type',
                                      options: MasterfilesApp::QualityRepo.new.for_select_inspection_failure_types,
                                      disabled_options: MasterfilesApp::QualityRepo.new.for_select_inactive_inspection_failure_types,
                                      required: true },
        passed_default: { renderer: :checkbox },

        applies_to_all_tm_groups: { renderer: :checkbox, caption: 'Applies to all TM Groups' },
        applicable_tm_group_ids: { renderer: :multi, caption: 'Target Market Groups',
                                   options: MasterfilesApp::TargetMarketRepo.new.for_select_tm_groups,
                                   selected: @form_object.applicable_tm_group_ids,
                                   hide_on_load: @form_object.applies_to_all_tm_groups },

        applies_to_all_grades: { renderer: :checkbox, caption: 'Applies to all Grades' },
        applicable_grade_ids: { renderer: :multi, caption: 'Grades',
                                options: MasterfilesApp::FruitRepo.new.for_select_grades,
                                selected: @form_object.applicable_grade_ids,
                                hide_on_load: @form_object.applies_to_all_grades }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_inspection_type(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(inspection_type_code: nil,
                                    description: nil,
                                    inspection_failure_type_id: nil,
                                    match_all: true,
                                    passed_default: false,
                                    applies_to_all_tm_groups: true,
                                    applicable_tm_group_ids: nil,
                                    applies_to_all_grades: true,
                                    applicable_grade_ids: nil)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.input_change :applies_to_all_tm_groups, notify: [{ url: '/masterfiles/quality/inspection_types/applies_to_all_tm_groups' }]
        behaviour.input_change :applies_to_all_grades, notify: [{ url: '/masterfiles/quality/inspection_types/applies_to_all_grades' }]
      end
    end
  end
end
