# frozen_string_literal: true

module UiRules
  class PeripheralRule < Base
    def generate_rules
      @repo = ProductionApp::ResourceRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      add_behaviours if @mode == :new

      form_name 'peripheral'
    end

    def set_show_fields
      plant_resource_type_id_label = @repo.find_plant_resource_type(@form_object.plant_resource_type_id)&.plant_resource_type_code
      fields[:plant_resource_type_id] = { renderer: :label, with_value: plant_resource_type_id_label, caption: 'Plant Resource Type' }
      fields[:plant_resource_code] = { renderer: :label }
      fields[:system_resource_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      type_renderer = if @mode == :new
                        { renderer: :select,
                          options: @repo.for_select_peripheral_types,
                          # disabled_options: @repo.for_select_inactive_peripheral_types,
                          caption: 'peripheral type', required: true, prompt: true }
                      else
                        plant_resource_type_id_label = @repo.find_plant_resource_type(@form_object.plant_resource_type_id)&.plant_resource_type_code
                        { renderer: :label, with_value: plant_resource_type_id_label, caption: 'Peripheral Type' }
                      end
      {
        plant_resource_type_id: type_renderer,
        plant_resource_code: { required: true },
        description: { required: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_plant_resource_flat(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(plant_resource_type_id: nil,
                                    system_resource_id: nil,
                                    plant_resource_code: nil,
                                    # plant_resource_attributes: nil,
                                    description: nil)
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :plant_resource_type_id, notify: [{ url: '/production/resources/peripherals/next_code' }]
      end
    end
  end
end
