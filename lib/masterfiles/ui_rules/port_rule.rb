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

    def set_show_fields
      port_type_id_label = @repo.find(:port_types, MasterfilesApp::PortType, @form_object.port_type_id)&.port_type_code
      voyage_type_id_label = @repo.find(:voyage_types, MasterfilesApp::VoyageType, @form_object.voyage_type_id)&.voyage_type_code
      fields[:port_type_id] = { renderer: :label, with_value: port_type_id_label, caption: 'Port Type' }
      fields[:voyage_type_id] = { renderer: :label, with_value: voyage_type_id_label, caption: 'Voyage Type' }
      fields[:port_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        port_type_id: { renderer: :select, options: MasterfilesApp::PortTypeRepo.new.for_select_port_types, disabled_options: MasterfilesApp::PortTypeRepo.new.for_select_inactive_port_types, caption: 'Port Type', required: true },
        voyage_type_id: { renderer: :select, options: MasterfilesApp::VoyageTypeRepo.new.for_select_voyage_types, disabled_options: MasterfilesApp::VoyageTypeRepo.new.for_select_inactive_voyage_types, caption: 'Voyage Type', required: true },
        port_code: { required: true, force_uppercase: true },
        description: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_port(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(port_type_id: nil,
                                    voyage_type_id: nil,
                                    port_code: nil,
                                    description: nil)
    end
  end
end
