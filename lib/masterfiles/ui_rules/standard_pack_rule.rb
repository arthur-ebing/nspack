# frozen_string_literal: true

module UiRules
  class StandardPackRule < Base
    def generate_rules
      @repo = MasterfilesApp::FruitSizeRepo.new
      @setup_repo = ProductionApp::ProductSetupRepo.new
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
      fields[:plant_resource_button_indicator] = {
        renderer: :label,
        hide_on_load: !AppConst::CR_PROD.provide_pack_type_at_carton_verification?
      }
      fields[:active] = { renderer: :label,
                          as_boolean: true }
      fields[:use_size_ref_for_edi] = { renderer: :label,
                                        as_boolean: true }
      fields[:palletizer_incentive_rate] = { renderer: :label }
      fields[:bin] = { renderer: :label,
                       caption: 'Bin?',
                       as_boolean: true }
      fields[:rmt_container_material_owner_id] = { renderer: :label,
                                                   with_value: @form_object.rmt_container_material_owner,
                                                   hide_on_load: !@form_object.bin,
                                                   caption: 'RMT Container Material Owner' }
      fields[:basic_pack_codes] = { renderer: :list,
                                    caption: 'Basic Packs',
                                    hide_on_load: @form_object.basic_pack_codes.empty?,
                                    items: @form_object.basic_pack_codes }
    end

    def common_fields
      {
        standard_pack_code: { required: true },
        description: {},
        std_pack_label_code: { caption: 'Label code' },
        material_mass: { required: true,
                         renderer: :numeric },
        plant_resource_button_indicator: {
          renderer: :select,
          options: @repo.for_select_plant_resource_button_indicator(Crossbeams::Config::ResourceDefinitions::MODULE_BUTTON),
          caption: 'Button Indicator',
          prompt: 'Select Button Indicator',
          hide_on_load: !AppConst::CR_PROD.provide_pack_type_at_carton_verification?,
          searchable: true,
          remove_search_for_small_list: false,
          hint: '<p>Selecting this indicator allows you to specify which std_pack is to be used for which button.</p>
                 <p>Then when the carton is verified, the correct standard pack will be assigned to the carton.</p>'
        },
        use_size_ref_for_edi: { renderer: :checkbox,
                                hint: '<p>When the checkbox is ticked:</p>
                                       <p>edi files will use the fruit_size_references.size_reference as the edi_size_count.</p>' },
        palletizer_incentive_rate: { required: true,
                                     renderer: :numeric },
        bin: { renderer: :checkbox,
               caption: 'Bin?',
               as_boolean: true  },
        rmt_container_material_owner_id: { renderer: :select,
                                           options: @setup_repo.for_select_rmt_container_material_owners,
                                           caption: 'RMT Container Material Owner',
                                           prompt: 'Select RMT Container Material Owner',
                                           searchable: true,
                                           remove_search_for_small_list: false,
                                           hide_on_load: !@form_object.bin },
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
                                    rmt_container_material_owner_id: nil,
                                    basic_pack_ids: [])
    end

    def handle_behaviour
      case @mode
      when :bin
        bin_change
      else
        unhandled_behaviour!
      end
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.input_change :bin, notify: [{ url: '/masterfiles/fruit/standard_pack_codes/bin_changed' }]
      end
    end

    def bin_change
      actions = if params[:changed_value] == 't'
                  [OpenStruct.new(type: :show_element, dom_id: 'standard_pack_rmt_container_material_owner_id_field_wrapper')]
                else
                  [OpenStruct.new(type: :hide_element, dom_id: 'standard_pack_rmt_container_material_owner_id_field_wrapper'),
                   OpenStruct.new(type: :change_select_value, dom_id: 'standard_pack_rmt_container_material_owner_id', value: '')]
                end
      json_actions(actions)
    end
  end
end
