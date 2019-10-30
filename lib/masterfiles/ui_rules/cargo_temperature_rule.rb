# frozen_string_literal: true

module UiRules
  class CargoTemperatureRule < Base
    def generate_rules
      @repo = MasterfilesApp::CargoTemperatureRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'cargo_temperature'
    end

    def set_show_fields
      fields[:temperature_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:set_point_temperature] = { renderer: :label }
      fields[:load_temperature] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        temperature_code: { force_uppercase: true, required: true },
        description: {},
        set_point_temperature: { renderer: :numeric, required: true },
        load_temperature: { renderer: :numeric }
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_cargo_temperature(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(temperature_code: nil,
                                    description: nil,
                                    set_point_temperature: nil,
                                    load_temperature: nil)
    end
  end
end
