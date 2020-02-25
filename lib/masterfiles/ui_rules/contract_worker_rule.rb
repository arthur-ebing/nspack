# frozen_string_literal: true

module UiRules
  class ContractWorkerRule < Base
    def generate_rules
      @repo = MasterfilesApp::HumanResourcesRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'contract_worker'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:employment_type_id] = { renderer: :label,
                                      with_value: @form_object.employment_type_code,
                                      caption: 'Employment Type' }
      fields[:contract_type_id] = { renderer: :label,
                                    with_value: @form_object.contract_type_code,
                                    caption: 'Contract Type' }
      fields[:wage_level_id] = { renderer: :label,
                                 with_value: @form_object.wage_level,
                                 caption: 'Wage Level' }
      fields[:shift_type_id] = { renderer: :label,
                                 with_value: @form_object.shift_type_code,
                                 caption: 'Shift Type',
                                 min_charwidth: 40 }
      fields[:first_name] = { renderer: :label }
      fields[:surname] = { renderer: :label }
      fields[:title] = { renderer: :label }
      fields[:email] = { renderer: :label }
      fields[:contact_number] = { renderer: :label }
      fields[:personnel_number] = { renderer: :label }
      fields[:start_date] = { renderer: :label }
      fields[:end_date] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        employment_type_id: { renderer: :select,
                              options: @repo.for_select_employment_types,
                              caption: 'Employment Type',
                              required: true },
        contract_type_id: { renderer: :select,
                            options: @repo.for_select_contract_types,
                            caption: 'Contract Type',
                            required: true },
        wage_level_id: { renderer: :select,
                         options: @repo.for_select_wage_levels,
                         caption: 'Wage Level',
                         required: true },
        shift_type_id: { renderer: :select,
                         options: @repo.for_select_shift_types_with_codes,
                         caption: 'Shift Type',
                         min_charwidth: 35,
                         prompt: true },
        first_name: { required: true },
        surname: { required: true },
        title: { force_uppercase: true },
        email: {},
        contact_number: {},
        personnel_number: { required: true },
        start_date: { renderer: :input,
                      subtype: :date,
                      required: true },
        end_date: { renderer: :input,
                    subtype: :date,
                    required: true },
        active: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_contract_worker(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(employment_type_id: nil,
                                    contract_type_id: nil,
                                    wage_level_id: nil,
                                    first_name: nil,
                                    surname: nil,
                                    title: nil,
                                    email: nil,
                                    contact_number: nil,
                                    personnel_number: nil,
                                    start_date: nil,
                                    end_date: nil,
                                    active: true)
    end
  end
end
