# frozen_string_literal: true

module UiRules
  class ShiftRule < Base
    def generate_rules
      @repo = ProductionApp::HumanResourcesRepo.new
      @mf_hr_repo = MasterfilesApp::HumanResourcesRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields @mode == :new ? new_fields : edit_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'shift'
    end

    def set_show_fields
      fields[:shift_type_id] = { renderer: :hidden }
      fields[:shift_type_code] = { renderer: :label, with_value: @form_object.shift_type_code, caption: 'Shift Type' }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:running_hours] = { renderer: :label }
      fields[:start_date_time] = { renderer: :label }
      fields[:end_date_time] = { renderer: :label }
    end

    def edit_fields
      {
        shift_type_id: { renderer: :hidden },
        shift_type_code: { renderer: :label, options: @form_object.shift_type_code, caption: 'Shift Type', required: true },
        running_hours: {},
        start_date_time: { renderer: :label },
        end_date_time: { renderer: :label }
      }
    end

    def new_fields
      {
        shift_type_id: { renderer: :select, options: @mf_hr_repo.for_select_shift_types_with_codes, caption: 'Shift Type', required: true },
        date: { renderer: :input, subtype: :date, caption: 'Please select', required: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_shift(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(shift_type_id: nil,
                                    running_hours: nil,
                                    start_date_time: nil,
                                    end_date_time: nil)
    end
  end
end
