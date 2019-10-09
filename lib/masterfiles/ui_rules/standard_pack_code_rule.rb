# frozen_string_literal: true

module UiRules
  class StandardPackCodeRule < Base
    def generate_rules
      @this_repo = MasterfilesApp::FruitSizeRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if @mode == :show

      form_name 'standard_pack_code'
    end

    def set_show_fields
      fields[:standard_pack_code] = { renderer: :label }
      fields[:material_mass] = { renderer: :label }
      fields[:plant_resource_button_indicator] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        standard_pack_code: { required: true },
        material_mass: { renderer: :numeric },
        plant_resource_button_indicator: { renderer: :select,
                                           options: @this_repo.for_select_plant_resource_button_indicator(Crossbeams::Config::ResourceDefinitions::MODULE_BUTTON),
                                           caption: 'Button Indicator',
                                           prompt: 'Select Button Indicator',
                                           searchable: true,
                                           remove_search_for_small_list: false }
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @this_repo.find_standard_pack_code(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(standard_pack_code: nil,
                                    material_mass: nil,
                                    plant_resource_button_indicator: nil)
    end
  end
end
