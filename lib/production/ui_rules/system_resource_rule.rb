# frozen_string_literal: true

module UiRules
  class SystemResourceRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @repo = ProductionApp::ResourceRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields
      extended_config_fields
      set_show_fields if %i[show deploy_config].include?(@mode)
      set_deploy_fields if @mode == :deploy_config

      add_peripheral_behaviours if @mode == :set_peripheral

      form_name 'system_resource'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      plant_resource_type_id_label = @repo.find_plant_resource_type(@form_object.plant_resource_type_id)&.plant_resource_type_code
      fields[:plant_resource_type_id] = { renderer: :label, with_value: plant_resource_type_id_label, caption: 'Plant Type' }
      fields[:plant_resource_code] = { renderer: :label, caption: 'Plant Code' }
      fields[:system_resource_type_code] = { renderer: :label, caption: 'System Type' }
      fields[:system_resource_code] = { renderer: :label, caption: 'System Code' }
      fields[:description] = { renderer: :label }
      fields[:represents_plant_resource_code] = { renderer: :label, invisible: @form_object.represents_plant_resource_code.nil?, caption: 'Represents' }
      fields[:active] = { renderer: :label, as_boolean: true }

      fields[:equipment_type] = { renderer: :label, invisible: @form_object.system_resource_type_code == Crossbeams::Config::ResourceDefinitions::MODULE_BUTTON }
      fields[:module_function] = { renderer: :label, invisible: @form_object.system_resource_type_code == Crossbeams::Config::ResourceDefinitions::MODULE_BUTTON }
      fields[:robot_function] = { renderer: :label, invisible: @form_object.system_resource_type_code == Crossbeams::Config::ResourceDefinitions::MODULE_BUTTON }
      fields[:mac_address] = { renderer: :label, invisible: @form_object.system_resource_type_code == Crossbeams::Config::ResourceDefinitions::MODULE_BUTTON }
      fields[:ip_address] = { renderer: :label, invisible: @form_object.system_resource_type_code == Crossbeams::Config::ResourceDefinitions::MODULE_BUTTON }
      fields[:port] = { renderer: :label, invisible: @form_object.system_resource_type_code == Crossbeams::Config::ResourceDefinitions::MODULE_BUTTON }
      fields[:ttl] = { renderer: :label, invisible: @form_object.system_resource_type_code == Crossbeams::Config::ResourceDefinitions::MODULE_BUTTON }
      fields[:cycle_time] = { renderer: :label, invisible: @form_object.system_resource_type_code == Crossbeams::Config::ResourceDefinitions::MODULE_BUTTON }
      fields[:publishing] = { renderer: :label, as_boolean: true, invisible: @form_object.system_resource_type_code == Crossbeams::Config::ResourceDefinitions::MODULE_BUTTON }
      fields[:login] = { renderer: :label, as_boolean: true, invisible: @form_object.system_resource_type_code == Crossbeams::Config::ResourceDefinitions::MODULE_BUTTON }
      fields[:logoff] = { renderer: :label, as_boolean: true, invisible: @form_object.system_resource_type_code == Crossbeams::Config::ResourceDefinitions::MODULE_BUTTON }
      fields[:group_incentive] = { renderer: :label, as_boolean: true, invisible: @form_object.system_resource_type_code == Crossbeams::Config::ResourceDefinitions::MODULE_BUTTON }
      fields[:legacy_messcada] = { renderer: :label, as_boolean: true, invisible: @form_object.system_resource_type_code == Crossbeams::Config::ResourceDefinitions::MODULE_BUTTON }
      fields[:module_action] = { renderer: :label }
      fields[:peripheral_model] = { renderer: :label }
      fields[:connection_type] = { renderer: :label }
      fields[:printer_language] = { renderer: :label }
      fields[:print_username] = { renderer: :label }
      fields[:print_password] = { renderer: :label }
      fields[:pixels_mm] = { renderer: :label }
      fields[:no_of_labels_to_print] = { renderer: :label,
                                         parent_field: :extended_config,
                                         invisible: @form_object.system_resource_type_code != Crossbeams::Config::ResourceDefinitions::MODULE_BUTTON }
    end

    def set_deploy_fields
      @form_object = OpenStruct.new(@form_object.to_h.merge(network_ip: nil, use_network_ip: false))
      fields[:network_ip] = {}
      fields[:use_network_ip] = { renderer: :checkbox }
      fields[:distro_type] = { renderer: :label,
                               with_value: Crossbeams::Config::ResourceDefinitions::MODULE_DISTRO_TYPES.rassoc((@form_object.extended_config || {})['distro_type']).first }
    end

    def common_fields
      plant_resource_type_id_label = @repo.get_value(:plant_resource_types, :plant_resource_type_code, id: @form_object.plant_resource_type_id)
      equipment_types = if %i[set_module set_server].include?(@mode)
                          module_types
                        else
                          peripheral_types
                        end
      {
        plant_resource_type_id: { renderer: :label, with_value: plant_resource_type_id_label, caption: 'Plant Resource Type' },
        system_resource_code: { renderer: :label },
        description: { renderer: :label },
        equipment_type: { renderer: :select, options: equipment_types, sort_items: false },
        module_function: {},
        robot_function: { renderer: :select, options: robot_functions, sort_items: false, prompt: true },
        mac_address: {},
        ip_address: {},
        port: { renderer: :integer },
        ttl: { renderer: :integer },
        cycle_time: { renderer: :integer },
        publishing: { renderer: :checkbox },
        login: { renderer: :checkbox },
        logoff: { renderer: :checkbox },
        group_incentive: { renderer: :checkbox },
        legacy_messcada: { renderer: :checkbox },
        module_action: { renderer: :select, options: Crossbeams::Config::ResourceDefinitions::MODULE_ACTIONS.keys },
        peripheral_model: { renderer: :select, options: peripheral_models },
        connection_type: { renderer: :select, options: connection_types },
        printer_language: { renderer: :select, options: printer_languages },
        print_username: {},
        print_password: {},
        pixels_mm: { renderer: :integer }
      }
    end

    def extended_config_fields
      fields[:no_of_labels_to_print] = { renderer: :integer,
                                         parent_field: :extended_config,
                                         invisible: @mode != :set_button }
      fields[:distro_type] = { renderer: :select,
                               options: Crossbeams::Config::ResourceDefinitions::MODULE_DISTRO_TYPES,
                               parent_field: :extended_config,
                               prompt: true,
                               invisible: @mode != :set_module }
      fields[:netmask] = { parent_field: :extended_config,
                           invisible: @mode != :set_server }
      fields[:gateway] = { parent_field: :extended_config,
                           invisible: @mode != :set_server }
    end

    def make_form_object
      @form_object = if %i[show deploy_config].include?(@mode)
                       sysres = @repo.find_system_resource_flat(@options[:id])
                       represents = @repo.packpoint_for_button(sysres.plant_resource_code)
                       OpenStruct.new(sysres.to_h.merge(represents_plant_resource_code: represents))
                     else
                       @repo.find_system_resource(@options[:id])
                     end
      set_module_function
    end

    def handle_behaviour
      case @mode
      when :peripheral_type
        peripheral_type_change
      else
        unhandled_behaviour!
      end
    end

    private

    def module_types
      Crossbeams::Config::ResourceDefinitions::MODULE_EQUIPMENT_TYPES
    end

    def peripheral_types
      # USBCOM - non-rs232 USB device (e.g. scanner for pltz)
      Crossbeams::Config::ResourceDefinitions::PRINTER_SET.keys + Crossbeams::Config::ResourceDefinitions::REMOTE_PRINTER_SET.keys << 'USBCOM'
    end

    def set_module_function # rubocop:disable Metrics/CyclomaticComplexity
      return unless @form_object.module_function.nil?

      mf = case @form_object.system_resource_code
           when /^BWM/
             'rmt-bin-weigher'
           when /^BTM/
             'rmt-bin-tip'
           when /^CLM/
             'carton-labelling'
           when /^CVM/
             'carton-verification'
           when /^PTM/
             'pallet-buildup'
           when /^PMM/
             'pallet-movement'
           when /^PWM/
             'pallet-weighing'
           when /^PRN/
             'NSLD-Printing'
           when /^SRV/
             'messerver'
           end
      @form_object = OpenStruct.new(@form_object.to_h.merge(module_function: mf)) unless mf.nil?
    end

    def robot_functions
      Crossbeams::Config::ResourceDefinitions::MODULE_ROBOT_FUNCTIONS
    end

    def peripheral_models
      if @form_object.equipment_type
        print_key = Crossbeams::Config::ResourceDefinitions::REMOTE_PRINTER_SET[@form_object.equipment_type] || @form_object.equipment_type
        Crossbeams::Config::ResourceDefinitions::PRINTER_SET[print_key]&.keys
      else
        []
      end
    end

    def connection_types
      %w[TCP USB]
    end

    def printer_languages
      %w[pplz zpl]
    end

    def add_peripheral_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :equipment_type,
                                  notify: [{ url: "/production/resources/system_resources/#{@options[:id]}/system_resource_element_changed/peripheral_type" }]
      end
    end

    def peripheral_type_change
      if @params[:changed_value].empty?
        sel = []
      else
        print_key = Crossbeams::Config::ResourceDefinitions::REMOTE_PRINTER_SET[@params[:changed_value]] || @params[:changed_value]
        sel = Crossbeams::Config::ResourceDefinitions::PRINTER_SET[print_key].keys
      end
      json_replace_select_options('system_resource_peripheral_model', sel)
    end
  end
end
