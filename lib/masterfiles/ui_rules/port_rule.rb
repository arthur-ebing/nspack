# frozen_string_literal: true

module UiRules
  class PortRule < Base
    def generate_rules
      @repo = MasterfilesApp::PortRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'port'
    end

    def set_show_fields
      fields[:port_type_ids] = { renderer: :label, with_value: @form_object&.port_type_codes, caption: 'Port Type' }
      fields[:voyage_type_ids] = { renderer: :label, with_value: @form_object&.voyage_type_codes, caption: 'Voyage Type' }
      fields[:city_id] = { renderer: :label, with_value: @form_object&.city_name, caption: 'City' }
      fields[:port_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        port_type_ids: { renderer: :multi,
                         options: MasterfilesApp::PortTypeRepo.new.for_select_port_types,
                         selected: @form_object.port_type_ids,
                         caption: 'Port Types',
                         required: true },
        voyage_type_ids: { renderer: :multi,
                           options: MasterfilesApp::VoyageTypeRepo.new.for_select_voyage_types,
                           selected: @form_object.voyage_type_ids,
                           caption: 'Voyage Types',
                           required: true },
        city_id: { renderer: :select,
                   options: MasterfilesApp::DestinationRepo.new.for_select_destination_cities,
                   caption: 'City',
                   prompt: true },
        port_code: { required: true, force_uppercase: true },
        description: {}
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_port_flat(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(port_type_ids: nil,
                                    voyage_type_ids: nil,
                                    city_id: nil,
                                    port_code: nil,
                                    description: nil)
    end
  end
end
