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
      basic_pack_code_id_label = @this_repo.find_basic_pack_code(@form_object.basic_pack_code_id)&.basic_pack_code
      fields[:standard_pack_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:std_pack_label_code] = { renderer: :label, caption: 'Label code' }
      fields[:material_mass] = { renderer: :label }
      fields[:plant_resource_button_indicator] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:basic_pack_code_id] = { renderer: :label, with_value: basic_pack_code_id_label, caption: 'Basic Pack Code' }
      fields[:use_size_ref_for_edi] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        standard_pack_code: { required: true },
        description: {},
        std_pack_label_code: { caption: 'Label code' },
        material_mass: { required: true,
                         renderer: :numeric },
        plant_resource_button_indicator: { renderer: :select,
                                           options: @this_repo.for_select_plant_resource_button_indicator(Crossbeams::Config::ResourceDefinitions::MODULE_BUTTON),
                                           caption: 'Button Indicator',
                                           prompt: 'Select Button Indicator',
                                           searchable: true,
                                           remove_search_for_small_list: false },
        basic_pack_code_id: { renderer: :select,
                              options: @this_repo.for_select_basic_pack_codes,
                              disabled_options: @this_repo.for_select_inactive_basic_pack_codes,
                              caption: 'Basic Pack Code',
                              invisible: AppConst::BASE_PACK_EQUALS_STD_PACK },
        use_size_ref_for_edi: { renderer: :checkbox }
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @this_repo.find_standard_pack_code(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(standard_pack_code: nil,
                                    description: nil,
                                    std_pack_label_code: nil,
                                    material_mass: nil,
                                    plant_resource_button_indicator: nil,
                                    basic_pack_code_id: nil,
                                    use_size_ref_for_edi: nil)
    end
  end
end
