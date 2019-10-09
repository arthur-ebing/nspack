# frozen_string_literal: true

module UiRules
  class VesselTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::VesselTypeRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'vessel_type'
    end

    def set_show_fields
      voyage_type_id_label = @repo.find(:voyage_types, MasterfilesApp::VoyageType, @form_object.voyage_type_id)&.voyage_type_code
      fields[:voyage_type_id] = { renderer: :label, with_value: voyage_type_id_label, caption: 'Voyage Type' }
      fields[:vessel_type_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        voyage_type_id: { renderer: :select, options: MasterfilesApp::VoyageTypeRepo.new.for_select_voyage_types, disabled_options: MasterfilesApp::VoyageTypeRepo.new.for_select_inactive_voyage_types, caption: 'Voyage Type', required: true },
        vessel_type_code: { required: true, force_uppercase: true },
        description: {}
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_vessel_type(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(voyage_type_id: nil,
                                    vessel_type_code: nil,
                                    description: nil)
    end
  end
end
