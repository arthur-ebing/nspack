# frozen_string_literal: true

module UiRules
  class SystemResourceRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @repo = ProductionApp::ResourceRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields
      set_show_fields if @mode == :show

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

      fields[:equipment_type] = { renderer: :label }
      fields[:module_function] = { renderer: :label }
      fields[:robot_function] = { renderer: :label }
      fields[:mac_address] = { renderer: :label }
      fields[:ip_address] = { renderer: :label }
      fields[:port] = { renderer: :label }
      fields[:ttl] = { renderer: :label }
      fields[:cycle_time] = { renderer: :label }
      fields[:publishing] = { renderer: :label, as_boolean: true }
      fields[:login] = { renderer: :label, as_boolean: true }
      fields[:logoff] = { renderer: :label, as_boolean: true }
      fields[:group_incentive] = { renderer: :label, as_boolean: true }
      fields[:legacy_messcada] = { renderer: :label, as_boolean: true }
      fields[:module_action] = { renderer: :label }
      fields[:peripheral_model] = { renderer: :label }
      fields[:connection_type] = { renderer: :label }
      fields[:printer_language] = { renderer: :label }
      fields[:print_username] = { renderer: :label }
      fields[:print_password] = { renderer: :label }
      fields[:pixels_mm] = { renderer: :label }
    end

    def common_fields
      plant_resource_type_id_label = @repo.get_value(:plant_resource_types, :plant_resource_type_code, id: @form_object.plant_resource_type_id)
      equipment_types = if @mode == :set_module
                          module_types
                        else
                          peripheral_types
                        end
      {
        plant_resource_type_id: { renderer: :label, with_value: plant_resource_type_id_label, caption: 'Plant Resource Type' },
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

    def make_form_object
      @form_object = if @mode == :show
                       sysres = @repo.find_system_resource_flat(@options[:id])
                       represents = @repo.packpoint_for_button(sysres.plant_resource_code)
                       OpenStruct.new(sysres.to_h.merge(represents_plant_resource_code: represents))
                     else
                       @repo.find_system_resource(@options[:id])
                     end
      set_module_function
    end

    private

    def module_types
      [
        ['MES Server', 'messerver'],
        ['CMS Server', 'cmsserver'],
        ['Standard NoSoft RPi robot (robot-nspi)', 'robot-nspi'],
        ['Client-built  RPi robot (robot-rpi)', 'robot-rpi'],
        ['Radical T200/T201 robot - Requires a MAC Address (robot-T200)', 'robot-T200'],
        ['Radical T210 Java robot (robot-T210)', 'robot-T210'],
        ['ITPC server', 'ITPC']
      ]
    end

    def peripheral_types
      %w[argox zebra datamax remote-argox remote-zebra remote-datamax USBCOM]
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
      %w[Server HTTP-CartonLabel HTTP-BinTip HTTP-RmtBinWeighing HTTP-PalletBuildup HTTP-PalletBuildup-SplitScreen]
    end

    def peripheral_models
      %w[GK420d gk420d argox Unknown]
    end

    def connection_types
      %w[TCP USB]
    end

    def printer_languages
      %w[pplz zpl]
    end
  end
end
