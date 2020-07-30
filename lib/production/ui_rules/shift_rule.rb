# frozen_string_literal: true

module UiRules
  class ShiftRule < Base
    def generate_rules  # rubocop:disable Metrics/AbcSize
      @repo = ProductionApp::HumanResourcesRepo.new
      @mf_hr_repo = MasterfilesApp::HumanResourcesRepo.new
      make_form_object
      apply_form_values

      # common_values_for_fields @mode == :new ? new_fields : edit_fields

      common_values_for_fields new_fields if %i[new filter summary_report].include? @mode
      common_values_for_fields edit_fields if @mode == :edit

      set_show_fields if %i[show reopen].include? @mode

      set_filter_fields if %i[filter].include? @mode
      set_summary_report_fields if %i[summary_report].include? @mode

      form_name 'shift'
    end

    def set_show_fields
      fields[:shift_type_id] = { renderer: :hidden }
      fields[:shift_type_code] = { renderer: :label, with_value: @form_object.shift_type_code, caption: 'Shift Type' }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:running_hours] = { renderer: :label }
      fields[:start_date_time] = { renderer: :label, format: :without_timezone_or_seconds }
      fields[:end_date_time] = { renderer: :label, format: :without_timezone_or_seconds }
    end

    def set_filter_fields
      fields[:from_date] = { renderer: :date,
                             required: true,
                             width: 1 }
      fields[:to_date] = { renderer: :date,
                           required: true }
      fields[:employment_type_id] = { renderer: :hidden }
      fields[:employment_type] = { renderer: :hidden }
      fields[:spacer] = { renderer: :hidden }
    end

    def set_summary_report_fields
      from_date_label = @form_object[:from_date]
      to_date_label = @form_object[:to_date]
      fields[:from_date_label] = { renderer: :label,
                                   with_value: from_date_label,
                                   caption: 'From Date' }
      fields[:to_date_label] = { renderer: :label,
                                 with_value: to_date_label,
                                 caption: 'To Date' }
      fields[:from_date] = { renderer: :hidden }
      fields[:to_date] = { renderer: :hidden }
      fields[:employment_type_id] = { renderer: :hidden }
      fields[:employment_type] = { renderer: :hidden }
      fields[:spacer] = { renderer: :hidden }
    end

    def edit_fields
      {
        shift_type_id: { renderer: :hidden },
        shift_type_code: { renderer: :label, options: @form_object.shift_type_code, caption: 'Shift Type', required: true },
        running_hours: {},
        start_date_time: { renderer: :label, format: :without_timezone_or_seconds },
        end_date_time: { renderer: :label, format: :without_timezone_or_seconds }
      }
    end

    def new_fields
      {
        shift_type_id: { renderer: :select, options: @mf_hr_repo.for_select_shift_types_with_codes, caption: 'Shift Type', required: true, prompt: true },
        date: { renderer: :input, subtype: :date, caption: 'Please select', required: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      return make_summary_report_object if %i[filter summary_report].include? @mode

      @form_object = @repo.find_shift(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(shift_type_id: nil,
                                    running_hours: nil,
                                    start_date_time: nil,
                                    end_date_time: nil)
    end

    def make_summary_report_object
      employment_type_id = @repo.select_values(:employment_types, :id, employment_type_code: @options[:employment_type].upcase).first
      @form_object = OpenStruct.new(from_date: @options[:attrs].nil? ? nil : @options[:attrs][:from_date],
                                    to_date: @options[:attrs].nil? ? nil : @options[:attrs][:to_date],
                                    employment_type: @options[:employment_type],
                                    employment_type_id: employment_type_id)
    end
  end
end
