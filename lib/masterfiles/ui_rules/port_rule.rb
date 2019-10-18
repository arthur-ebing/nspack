# frozen_string_literal: true

module UiRules
  class PortRule < Base
    def generate_rules
      @repo = MasterfilesApp::PortRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'port'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      port_type_id_label = MasterfilesApp::PortTypeRepo.new.find_port_type(@form_object.port_type_id)&.port_type_code
      voyage_type_id_label = MasterfilesApp::VoyageTypeRepo.new.find_voyage_type(@form_object.voyage_type_id)&.voyage_type_code
      city_id_label = MasterfilesApp::DestinationRepo.new.find_destination_city(@form_object.city_id)&.city_name
      fields[:port_type_id] = { renderer: :label, with_value: port_type_id_label, caption: 'Port Type' }
      fields[:voyage_type_id] = { renderer: :label, with_value: voyage_type_id_label, caption: 'Voyage Type' }
      fields[:city_id] = { renderer: :label, with_value: city_id_label, caption: 'City' }
      fields[:port_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        port_type_id: { renderer: :select,
                        options: MasterfilesApp::PortTypeRepo.new.for_select_port_types,
                        caption: 'Port Type',
                        required: true },
        voyage_type_id: { renderer: :select,
                          options: MasterfilesApp::VoyageTypeRepo.new.for_select_voyage_types,
                          caption: 'Voyage Type',
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

      @form_object = @repo.find_port(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(port_type_id: nil,
                                    voyage_type_id: nil,
                                    city_id: nil,
                                    port_code: nil,
                                    description: nil)
    end
  end
end
