# frozen_string_literal: true

module UiRules
  class VehicleTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::VehicleTypeRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'vehicle_type'
    end

    def set_show_fields
      fields[:vehicle_type_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:has_container] = { renderer: :label, as_boolean: true }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        vehicle_type_code: { required: true, force_uppercase: true },
        description: {},
        has_container: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_vehicle_type(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(vehicle_type_code: nil,
                                    description: nil,
                                    has_container: nil)
    end
  end
end
