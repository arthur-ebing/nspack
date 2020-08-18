# frozen_string_literal: true

module UiRules
  class ShiftRule < Base
    def generate_rules # rubocop:disable Metrics/AbcSize
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
      fields[:shift_type_code] = { renderer: :label,
                                   with_value: @form_object.shift_type_code,
                                   caption: 'Shift Type' }
      fields[:active] = { renderer: :label,
                          as_boolean: true }
      fields[:running_hours] = { renderer: :label }
      fields[:start_date_time] = { renderer: :label,
                                   format: :without_timezone_or_seconds }
      fields[:end_date_time] = { renderer: :label,
                                 format: :without_timezone_or_seconds }
    end

    def set_filter_fields
      fields[:from_date] = { renderer: :datetime,
                             required: true }
      fields[:to_date] = { renderer: :datetime,
                           required: true }
      fields[:employment_type_id] = { renderer: :hidden }
      fields[:employment_type] = { renderer: :hidden }
      fields[:spacer] = { renderer: :hidden }
    end

    def set_summary_report_fields
      fields[:from_date_label] = { renderer: :label,
                                   format: :without_timezone_or_seconds,
                                   with_value: DateTime.parse(@form_object[:from_date]).strftime('%Y-%m-%d %H:%M:%S'),
                                   caption: 'From Date' }
      fields[:to_date_label] = { renderer: :label,
                                 format: :without_timezone_or_seconds,
                                 with_value: DateTime.parse(@form_object[:to_date]).strftime('%Y-%m-%d %H:%M:%S'),
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
        shift_type_code: { renderer: :label,
                           options: @form_object.shift_type_code,
                           caption: 'Shift Type',
                           required: true },
        running_hours: {},
        start_date_time: { renderer: :label,
                           format: :without_timezone_or_seconds },
        end_date_time: { renderer: :label,
                         format: :without_timezone_or_seconds }
      }
    end

    def new_fields
      {
        shift_type_id: { renderer: :select,
                         options: @mf_hr_repo.for_select_shift_types_with_codes,
                         caption: 'Shift Type',
                         required: true,
                         prompt: true },
        date: { renderer: :input,
                subtype: :date,
                caption: 'Please select',
                required: true }
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

    def make_summary_report_object # rubocop:disable Metrics/AbcSize
      employment_type_code = @options[:employment_type].include?('pack') ? 'PACKERS' : 'PALLETIZER'
      employment_type_id = @repo.get_id(:employment_types, employment_type_code: employment_type_code)
      @form_object = OpenStruct.new(from_date: @options[:attrs].nil? ? (Date.today - 14).to_time : @options[:attrs][:from_date],
                                    to_date: @options[:attrs].nil? ? Date.today.next_day.to_time - 1 : @options[:attrs][:to_date],
                                    employment_type: employment_type_code.downcase,
                                    employment_type_id: employment_type_id)
    end
  end
end
