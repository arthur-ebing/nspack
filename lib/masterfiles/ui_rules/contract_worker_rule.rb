# frozen_string_literal: true

module UiRules
  class ContractWorkerRule < Base
    def generate_rules
      @repo = MasterfilesApp::HumanResourcesRepo.new
      @hr_messcada_repo = MesscadaApp::HrRepo.new
      @print_repo = LabelApp::PrinterRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      set_print_fields if @mode == :print_barcode
      set_packer_role_fields if @mode == :packer_role

      form_name 'contract_worker'
    end

    def set_packer_role_fields
      fields[:first_name] = { renderer: :label }
      fields[:surname] = { renderer: :label }
      fields[:title] = { renderer: :label }
      fields[:personnel_number] = { renderer: :label }
      fields[:packer_role_id] = { renderer: :select,
                                  options: @repo.for_select_contract_worker_packer_roles,
                                  caption: 'Packer role',
                                  min_charwidth: 35 }
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:employment_type_id] = { renderer: :label,
                                      with_value: @form_object.employment_type_code,
                                      caption: 'Employment Type' }
      fields[:contract_type_id] = { renderer: :label,
                                    with_value: @form_object.contract_type_code,
                                    caption: 'Contract Type' }
      fields[:wage_level_id] = { renderer: :label,
                                 with_value: UtilityFunctions.delimited_number(@form_object.wage_level),
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
      fields[:packer_role_id] = { renderer: :label,
                                  with_value: @form_object.packer_role,
                                  invisible: !AppConst::CR_PROD.group_incentive_has_packer_roles? }
      fields[:personnel_identifier_id] = { renderer: :label,
                                           with_value: identifier_label }
    end

    def set_print_fields
      fields[:personnel_number] = { renderer: :label }
      fields[:printer] = { renderer: :select,
                           options: @print_repo.select_printers_for_application(AppConst::PRINT_APP_PERSONNEL),
                           required: true }
      fields[:no_of_prints] = { renderer: :integer, required: true }
    end

    def common_fields
      packer_role_renderer = if worker_in_active_group
                               { renderer: :label,
                                 with_value: @form_object.packer_role,
                                 invisible: !AppConst::CR_PROD.group_incentive_has_packer_roles? }
                             else
                               { renderer: :select,
                                 options: @repo.for_select_contract_worker_packer_roles,
                                 caption: 'Packer role',
                                 min_charwidth: 35,
                                 prompt: true,
                                 required: true,
                                 invisible: !AppConst::CR_PROD.group_incentive_has_packer_roles? }
                             end

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
        packer_role_id: packer_role_renderer,
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
      @form_object = OpenStruct.new(@form_object.to_h.merge(printer: @print_repo.default_printer_for_application(AppConst::PRINT_APP_PERSONNEL), no_of_prints: 1)) if @mode == :print_barcode
    end

    def make_new_form_object
      default_packer_role = @repo.default_packer_role
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
                                    packer_role_id: default_packer_role,
                                    active: true)
    end

    def worker_in_active_group
      return false if @mode == :new

      @hr_messcada_repo.packer_belongs_to_active_incentive_group?(@form_object.id)
    end

    def identifier_label
      @repo.find_personnel_identifier(@form_object.personnel_identifier_id)&.identifier
    end
  end
end
