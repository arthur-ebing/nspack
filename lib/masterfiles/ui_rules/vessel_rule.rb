# frozen_string_literal: true

module UiRules
  class VesselRule < Base
    def generate_rules
      @repo = MasterfilesApp::VesselRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'vessel'
    end

    def set_show_fields
      vessel_type_id_label = @repo.find(:vessel_types, MasterfilesApp::VesselType, @form_object.vessel_type_id)&.vessel_type_code
      fields[:vessel_type_id] = { renderer: :label, with_value: vessel_type_id_label, caption: 'Vessel Type' }
      fields[:vessel_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        vessel_type_id: { renderer: :select,
                          options: MasterfilesApp::VesselTypeRepo.new.for_select_vessel_types,
                          caption: 'Vessel Type', required: true },
        vessel_code: { required: true },
        description: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_vessel_flat(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(vessel_type_id: nil,
                                    vessel_code: nil,
                                    description: nil)
    end
  end
end
