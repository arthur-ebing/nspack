# frozen_string_literal: true

module UiRules
  class InspectionTypeRule < Base  # rubocop:disable Metrics/ClassLength
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

      fields[:applies_to_all_tms] = { renderer: :label, caption: 'Applies To All Target Markets',
                                      as_boolean: true }
      fields[:applicable_tms] = { renderer: :label, caption: 'Applicable Target Markets',
                                  with_value: @form_object.applicable_tms.join(', ') }

      fields[:applies_to_all_tm_customers] = { renderer: :label, caption: 'Applies To All TM Customers',
                                               as_boolean: true }
      fields[:applicable_tm_customers] = { renderer: :label, caption: 'Applicable TM Customers',
                                           with_value: @form_object.applicable_tm_customers.join(', ') }

      fields[:applies_to_all_grades] = { renderer: :label, as_boolean: true }
      fields[:applicable_grades] = { renderer: :label, with_value: @form_object.applicable_grades.join(', ') }

      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      {
        inspection_type_code: { required: true },
        description: {},
        inspection_failure_type_id: { renderer: :select, caption: 'Inspection Failure Type',
                                      options: MasterfilesApp::QualityRepo.new.for_select_inspection_failure_types,
                                      disabled_options: MasterfilesApp::QualityRepo.new.for_select_inactive_inspection_failure_types,
                                      required: true },
        passed_default: { renderer: :checkbox },

        applies_to_all_tms: { renderer: :checkbox, caption: 'Applies to all Target Markets' },
        applicable_tm_ids: { renderer: :multi, caption: 'Target Markets',
                             options: MasterfilesApp::TargetMarketRepo.new.for_select_target_markets,
                             selected: @form_object.applicable_tm_ids,
                             hide_on_load: @form_object.applies_to_all_tms },

        applies_to_all_tm_customers: { renderer: :checkbox, caption: 'Applies to all TM Customers' },
        applicable_tm_customer_ids: { renderer: :multi, caption: 'Target Market Customers',
                                      options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_TARGET_CUSTOMER),
                                      selected: @form_object.applicable_tm_customer_ids,
                                      hide_on_load: @form_object.applies_to_all_tm_customers },

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
                                    applies_to_all_tms: true,
                                    applicable_tm_ids: nil,
                                    applies_to_all_tm_customers: true,
                                    applicable_tm_customer_ids: nil,
                                    applies_to_all_grades: true,
                                    applicable_grade_ids: nil)
    end

    def handle_behaviour
      changed = {
        applies_to_all_tms: :applies_to_all_tms,
        applies_to_all_tm_customers: :applies_to_all_tm_customers,
        applies_to_all_grades: :applies_to_all_grades
      }
      changed = changed[@options[:field]]
      return unhandled_behaviour! if changed.nil?

      send(changed)
    end

    private

    def add_behaviours
      url = "/masterfiles/quality/inspection_types/change/#{@mode}"
      behaviours do |behaviour|
        behaviour.input_change :applies_to_all_tms, notify: [{ url: "#{url}/applies_to_all_tms" }]
        behaviour.input_change :applies_to_all_tm_customers, notify: [{ url: "#{url}/applies_to_all_tm_customers" }]
        behaviour.input_change :applies_to_all_grades, notify: [{ url: "#{url}/applies_to_all_grades" }]
      end
    end

    def applies_to_all_tms
      actions = []
      actions << OpenStruct.new(type: params[:changed_value] == 'f' ? :show_element : :hide_element,
                                dom_id: 'inspection_type_applicable_tm_ids_field_wrapper')
      actions << OpenStruct.new(type: :replace_input_value, dom_id: 'inspection_type_applicable_tm_ids', value: [])
      json_actions(actions)
    end

    def applies_to_all_tm_customers
      actions = []
      actions << OpenStruct.new(type: params[:changed_value] == 'f' ? :show_element : :hide_element,
                                dom_id: 'inspection_type_applicable_tm_customer_ids_field_wrapper')
      actions << OpenStruct.new(type: :replace_input_value, dom_id: 'inspection_type_applicable_tm_customer_ids', value: [])
      json_actions(actions)
    end

    def applies_to_all_grades
      actions = []
      actions << OpenStruct.new(type: params[:changed_value] == 'f' ? :show_element : :hide_element,
                                dom_id: 'inspection_type_applicable_grade_ids_field_wrapper')
      actions << OpenStruct.new(type: :replace_input_value, dom_id: 'inspection_type_applicable_grade_ids', value: [])
      json_actions(actions)
    end
  end
end
