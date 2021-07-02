# frozen_string_literal: true

module UiRules
  class PackingSpecificationWizardFruitRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      form_name 'packing_specification_wizard'

      common_values_for_fields common_fields
      make_header_table
      add_behaviours
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      make_form_object
      actual_count = @fruit_size_repo.find_fruit_actual_counts_for_pack(@form_object.fruit_actual_counts_for_pack_id)
      actual_count ||= OpenStruct.new(standard_pack_code_ids: @repo.select_values(:standard_pack_codes, :id),
                                      size_reference_ids: @repo.select_values(:fruit_size_references, :id))
      {
        product_setup_template_id: { renderer: :hidden },
        commodity_id: { renderer: :select,
                        options: @setup_repo.for_select_template_cultivar_commodities(
                          @form_object.cultivar_group_id,
                          @form_object.cultivar_id
                        ),
                        disabled_options: @commodity_repo.for_select_inactive_commodities,
                        prompt: true,
                        required: true,
                        caption: 'Commodity' },
        marketing_variety_id: { renderer: :select,
                                options: @setup_repo.for_select_template_commodity_marketing_varieties(
                                  @form_object.product_setup_template_id,
                                  @form_object.commodity_id,
                                  @form_object.cultivar_id
                                ),
                                disabled_options: MasterfilesApp::CultivarRepo.new.for_select_inactive_marketing_varieties,
                                prompt: true,
                                required: true,
                                caption: 'Marketing Variety' },
        std_fruit_size_count_id: { renderer: :select,
                                   options: @fruit_size_repo.for_select_std_fruit_size_counts(
                                     where: { commodity_id: @form_object.commodity_id }
                                   ),
                                   disabled_options: @fruit_size_repo.for_select_inactive_std_fruit_size_counts,
                                   hide_on_load: !@requires_standard_counts,
                                   prompt: true,
                                   caption: 'Std Size Count' },
        basic_pack_code_id: { renderer: :select,
                              options: @fruit_size_repo.for_select_basic_packs,
                              disabled_options: @fruit_size_repo.for_select_inactive_basic_packs,
                              prompt: true,
                              required: true,
                              caption: 'Basic Pack' },
        standard_pack_code_id: { renderer: :select,
                                 options: @fruit_size_repo.for_select_standard_packs(
                                   where: { id: actual_count.standard_pack_code_ids }
                                 ),
                                 disabled_options: @fruit_size_repo.for_select_inactive_standard_packs,
                                 prompt: true,
                                 required: !@basic_equals_standard_pack,
                                 hide_on_load: @basic_equals_standard_pack,
                                 caption: 'Standard Pack' },
        fruit_actual_counts_for_pack_id: { renderer: :select,
                                           options: @fruit_size_repo.for_select_fruit_actual_counts_for_packs(
                                             where: { basic_pack_code_id: @form_object.basic_pack_code_id,
                                                      std_fruit_size_count_id: @form_object.std_fruit_size_count_id }
                                           ),
                                           disabled_options: @fruit_size_repo.for_select_inactive_fruit_actual_counts_for_packs,
                                           hide_on_load: !@requires_standard_counts,
                                           prompt: true,
                                           caption: 'Actual Count' },
        fruit_size_reference_id: { renderer: :select,
                                   options: @fruit_size_repo.for_select_fruit_size_references(
                                     where: { id: actual_count.size_reference_ids }
                                   ),
                                   disabled_options: @fruit_size_repo.for_select_inactive_fruit_size_references,
                                   prompt: true,
                                   required: @requires_standard_counts,
                                   caption: 'Size Reference' },
        rmt_class_id: { renderer: :select,
                        options: @fruit_repo.for_select_rmt_classes,
                        disabled_options: @fruit_repo.for_select_inactive_rmt_classes,
                        prompt: true,
                        caption: 'Class' },
        grade_id: { renderer: :select,
                    options: @fruit_repo.for_select_grades,
                    disabled_options: @fruit_repo.for_select_inactive_grades,
                    prompt: true,
                    required: true,
                    caption: 'Grade' }
      }
    end

    def make_form_object
      @repo = ProductionApp::PackingSpecificationRepo.new
      @fruit_size_repo = MasterfilesApp::FruitSizeRepo.new
      @fruit_repo = MasterfilesApp::FruitRepo.new
      @setup_repo = ProductionApp::ProductSetupRepo.new
      @commodity_repo = MasterfilesApp::CommodityRepo.new

      apply_form_values
      form_object_merge!(@repo.extend_packing_specification(@form_object))

      @requires_standard_counts ||= @repo.get(:commodities, @form_object.commodity_id, :requires_standard_counts) || true
      @basic_equals_standard_pack = AppConst::CR_MF.basic_pack_equals_standard_pack?
    end

    def make_header_table
      compact_header(UtilityFunctions.symbolize_keys(@form_object.compact_header))
    end

    def handle_behaviour
      changed = {
        commodity: :commodity_changed,
        basic_pack: :basic_pack_changed,
        std_fruit_size_count: :std_fruit_size_count_changed,
        actual_count: :actual_count_changed
      }
      changed = changed[@options[:field]]
      return unhandled_behaviour! if changed.nil?

      send(changed)
    end

    private

    def add_behaviours
      url = "/production/packing_specifications/wizard/change/packing_specification_wizard_fruit/#{@mode}"
      behaviours do |behaviour|
        behaviour.dropdown_change :commodity_id,
                                  notify: [{ url: "#{url}/commodity" }]
        behaviour.dropdown_change :basic_pack_code_id,
                                  notify: [{ url: "#{url}/basic_pack",
                                             param_keys: %i[packing_specification_wizard_commodity_id
                                                            packing_specification_wizard_std_fruit_size_count_id] }]
        behaviour.dropdown_change :std_fruit_size_count_id,
                                  notify: [{ url: "#{url}/std_fruit_size_count",
                                             param_keys: %i[packing_specification_wizard_commodity_id
                                                            packing_specification_wizard_basic_pack_code_id] }]
        behaviour.dropdown_change :fruit_actual_counts_for_pack_id,
                                  notify: [{ url: "#{url}/actual_count" }]
      end
    end

    def commodity_changed # rubocop:disable Metrics/AbcSize
      form_object_merge!(params)
      @form_object[:commodity_id] = params[:changed_value].to_i
      fields = common_fields

      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packing_specification_wizard_marketing_variety_id',
                                   options_array: fields[:marketing_variety_id][:options]),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packing_specification_wizard_std_fruit_size_count_id',
                                   options_array: fields[:std_fruit_size_count_id][:options]),
                    OpenStruct.new(type: fields[:std_fruit_size_count_id][:hide_on_load] ? :hide_element : :show_element,
                                   dom_id: 'packing_specification_wizard_std_fruit_size_count_id_field_wrapper'),
                    OpenStruct.new(type: fields[:fruit_actual_counts_for_pack_id][:hide_on_load] ? :hide_element : :show_element,
                                   dom_id: 'packing_specification_wizard_fruit_actual_counts_for_pack_id_field_wrapper')])
    end

    def basic_pack_changed
      form_object_merge!(params)
      @form_object[:basic_pack_code_id] = params[:changed_value].to_i
      @form_object[:commodity_id] = params[:packing_specification_wizard_commodity_id].to_i
      @form_object[:std_fruit_size_count_id] = params[:packing_specification_wizard_std_fruit_size_count_id].to_i
      fields = common_fields

      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packing_specification_wizard_fruit_actual_counts_for_pack_id',
                                   options_array: fields[:fruit_actual_counts_for_pack_id][:options])])
    end

    def std_fruit_size_count_changed
      form_object_merge!(params)
      @form_object[:std_fruit_size_count_id] = params[:changed_value].to_i
      @form_object[:commodity_id] = params[:packing_specification_wizard_commodity_id].to_i
      @form_object[:basic_pack_code_id] = params[:packing_specification_wizard_basic_pack_code_id].to_i
      fields = common_fields

      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packing_specification_wizard_fruit_actual_counts_for_pack_id',
                                   options_array: fields[:fruit_actual_counts_for_pack_id][:options])])
    end

    def actual_count_changed
      form_object_merge!(params)
      @form_object[:fruit_actual_counts_for_pack_id] = params[:changed_value].to_i
      fields = common_fields

      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packing_specification_wizard_standard_pack_code_id',
                                   options_array: fields[:standard_pack_code_id][:options]),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packing_specification_wizard_fruit_size_reference_id',
                                   options_array: fields[:fruit_size_reference_id][:options])])
    end
  end
end
