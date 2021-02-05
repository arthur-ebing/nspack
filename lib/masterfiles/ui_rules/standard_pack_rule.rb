# frozen_string_literal: true

module UiRules
  class StandardPackRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @repo = MasterfilesApp::FruitSizeRepo.new
      make_form_object
      apply_form_values
      add_behaviours unless @mode == :show
      common_values_for_fields common_fields

      set_show_fields if @mode == :show

      form_name 'standard_pack'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:standard_pack_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:std_pack_label_code] = { renderer: :label,
                                       caption: 'Label code' }
      fields[:material_mass] = { renderer: :label }
      fields[:plant_resource_button_indicator] = { renderer: :label }
      fields[:active] = { renderer: :label,
                          as_boolean: true }
      fields[:use_size_ref_for_edi] = { renderer: :label,
                                        as_boolean: true }
      fields[:palletizer_incentive_rate] = { renderer: :label }
      fields[:bin] = { renderer: :label,
                       caption: 'Bin?',
                       as_boolean: true }
      fields[:rmt_container_type_id] = { renderer: :label,
                                         with_value: @form_object.container_type,
                                         hide_on_load: !@form_object.bin,
                                         caption: 'Container Type' }
      fields[:rmt_container_material_type_id] = { renderer: :label,
                                                  with_value: @form_object.material_type,
                                                  hide_on_load: !@form_object.bin,
                                                  caption: 'Material Type' }
      fields[:basic_pack_codes] = { renderer: :list,
                                    caption: 'Basic Packs',
                                    hide_on_load: @form_object.basic_pack_codes.empty?,
                                    items: @form_object.basic_pack_codes }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      {
        standard_pack_code: { required: true },
        description: {},
        std_pack_label_code: { caption: 'Label code' },
        material_mass: { required: true,
                         renderer: :numeric },
        plant_resource_button_indicator: { renderer: :select,
                                           options: @repo.for_select_plant_resource_button_indicator(Crossbeams::Config::ResourceDefinitions::MODULE_BUTTON),
                                           caption: 'Button Indicator',
                                           prompt: 'Select Button Indicator',
                                           searchable: true,
                                           remove_search_for_small_list: false },
        use_size_ref_for_edi: { renderer: :checkbox },
        palletizer_incentive_rate: { required: true,
                                     renderer: :numeric },
        bin: { renderer: :checkbox,
               caption: 'Bin?',
               as_boolean: true  },
        rmt_container_type_id: { renderer: :select,
                                 options: MasterfilesApp::RmtContainerTypeRepo.new.for_select_rmt_container_types,
                                 disabled_options: MasterfilesApp::RmtContainerTypeRepo.new.for_select_inactive_rmt_container_types,
                                 prompt: true,
                                 hide_on_load: !@form_object.bin,
                                 caption: 'Container Type' },
        rmt_container_material_type_id: { renderer: :select,
                                          options: MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_rmt_container_material_types(
                                            where: { rmt_container_type_id: @form_object.rmt_container_type_id }
                                          ),
                                          disabled_options: MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_inactive_rmt_container_material_types,
                                          prompt: true,
                                          hide_on_load: !@form_object.bin,
                                          caption: 'Material Type' },
        basic_pack_ids: { renderer: :multi,
                          caption: 'Basic Packs',
                          options: @repo.for_select_basic_packs,
                          selected: @form_object.basic_pack_ids,
                          hide_on_load: AppConst::CR_MF.basic_pack_equals_standard_pack?,
                          required: false }

      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_standard_pack(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(description: nil,
                                    std_pack_label_code: nil,
                                    material_mass: nil,
                                    plant_resource_button_indicator: nil,
                                    basic_pack_code_id: nil,
                                    use_size_ref_for_edi: false,
                                    palletizer_incentive_rate: 0.0,
                                    bin: false,
                                    rmt_container_type_id: nil,
                                    rmt_container_material_type_id: nil,
                                    basic_pack_ids: [])
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.input_change :bin, notify: [{ url: '/masterfiles/fruit/standard_pack_codes/bin_changed' }]
        behaviour.dropdown_change :rmt_container_type_id, notify: [{ url: '/masterfiles/fruit/standard_pack_codes/container_type_changed' }]
      end
    end
  end
end
