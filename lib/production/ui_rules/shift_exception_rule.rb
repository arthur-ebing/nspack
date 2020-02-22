# frozen_string_literal: true

module UiRules
  class ShiftExceptionRule < Base
    def generate_rules
      @repo = ProductionApp::HumanResourcesRepo.new
      @mf_hr_repo = MasterfilesApp::HumanResourcesRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields case @mode
                               when :preselect
                                 preselect_fields
                               else
                                 common_fields
                               end

      set_show_fields if %i[show reopen].include? @mode

      form_name 'shift_exception'
    end

    def set_show_fields
      fields[:shift_id] = { renderer: :label, with_value: shift_type_code, caption: 'Shift' }
      fields[:contract_worker_id] = { renderer: :hidden }
      fields[:contract_worker_name] = { renderer: :label, caption: 'Contract Worker' }
      fields[:remarks] = { renderer: :label }
      fields[:running_hours] = { renderer: :label }
    end

    def preselect_fields
      {
        shift_id: { renderer: :hidden },
        contract_worker_id: {
          renderer: :select,
          options: @repo.for_select_contract_workers_for_shift(shift_id),
          caption: 'Contract Worker',
          min_charwidth: 30,
          required: true
        }
      }
    end

    def common_fields
      {
        shift_id: { renderer: :hidden },
        contract_worker_id: { renderer: :hidden },
        contract_worker_name: { renderer: :label, caption: 'Contract Worker', with_value: contract_worker_name },
        running_hours: { required: true },
        remarks: { renderer: :textarea, rows: 8 }
      }
    end

    def make_form_object
      if @mode == :preselect
        make_preselect_form_object
        return
      elsif @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_shift_exception(@options[:id])
    end

    def make_preselect_form_object
      @form_object = OpenStruct.new(shift_id: nil,
                                    contract_worker_id: nil)
    end

    def make_new_form_object
      @form_object = OpenStruct.new(shift_id: @options[:shift_id],
                                    contract_worker_id: @options[:contract_worker_id],
                                    remarks: nil,
                                    running_hours: nil)
    end

    private

    def shift_id
      @options[:shift_id] || @form_object&.shift_id
    end

    def contract_worker_name
      @mf_hr_repo.find_contract_worker(@options[:contract_worker_id])&.contract_worker_name
    end

    def shift_type_code
      shift_id = @form_object.shift_id
      @repo.find_shift(shift_id)&.shift_type_code
    end
  end
end
