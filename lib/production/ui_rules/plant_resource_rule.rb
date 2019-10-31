# frozen_string_literal: true

module UiRules
  class PlantResourceRule < Base
    def generate_rules
      @repo = ProductionApp::ResourceRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      set_edit_fields if @mode == :edit

      add_behaviours if @mode == :new

      form_name 'plant_resource'
    end

    def set_show_fields
      plant_resource_type_id_label = @repo.find_plant_resource_type(@form_object.plant_resource_type_id)&.plant_resource_type_code
      fields[:plant_resource_type_id] = { renderer: :label, with_value: plant_resource_type_id_label, caption: 'Plant Resource Type' }
      fields[:plant_resource_code] = { renderer: :label }
      fields[:system_resource_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def set_edit_fields # rubocop:disable Metrics/AbcSize
      rules = @repo.plant_resource_definition(@form_object.plant_resource_type_id)
      fields[:plant_resource_code][:readonly] = true if rules[:non_editable_code]

      at_ph_level = @form_object.plant_resource_type_code == Crossbeams::Config::ResourceDefinitions::PACKHOUSE
      at_gln_level = @form_object.plant_resource_type_code == Crossbeams::Config::ResourceDefinitions::LINE
      at_phc_level = @form_object.plant_resource_type_code == AppConst::PHC_LEVEL
      fields[:location_id] = { renderer: :lookup,
                               lookup_name: :plant_resource_locations,
                               lookup_key: :standard,
                               # param_values: { plant_resource_id: @options[:id] },
                               hidden_fields: %i[location_id],
                               show_field: :location_long_code,
                               caption: 'Select Location',
                               invisible: !at_ph_level }
      fields[:gln] = { renderer: :select,
                       options: AppConst::GLN_OR_LINE_NUMBERS,
                       prompt: true,
                       parent_field: :resource_properties,
                       invisible: !at_gln_level }
      fields[:phc] = { parent_field: :resource_properties,
                       invisible: !at_phc_level }
      fields[:packhouse_no] = { renderer: :integer,
                                required: true,
                                parent_field: :resource_properties,
                                invisible: !at_ph_level }
    end

    def common_fields
      type_renderer = if @mode == :new
                        { renderer: :select,
                          options: @repo.for_select_plant_resource_types(parent_type),
                          disabled_options: @repo.for_select_inactive_plant_resource_types,
                          caption: 'plant resource type', required: true }
                      else
                        plant_resource_type_id_label = @repo.find_plant_resource_type(@form_object.plant_resource_type_id)&.plant_resource_type_code
                        { renderer: :label, with_value: plant_resource_type_id_label, caption: 'Plant Resource Type' }
                      end
      {
        plant_resource_type_id: type_renderer,
        plant_resource_code: { required: true },
        description: { required: true }
      }
    end

    def parent_type
      return nil if @options[:parent_id].nil?

      @repo.plant_resource_type_code_for(@options[:parent_id])
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
        behaviour.dropdown_change :plant_resource_type_id, notify: [{ url: '/production/resources/plant_resources/next_code' }]
      end
    end
  end
end
