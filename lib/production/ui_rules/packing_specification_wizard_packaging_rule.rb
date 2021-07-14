# frozen_string_literal: true

module UiRules
  class PackingSpecificationWizardPackagingRule < Base
    def generate_rules
      form_name 'packing_specification_wizard'

      common_values_for_fields common_fields
      make_header_table
      add_behaviours
    end

    def common_fields
      make_form_object
      {
        pallet_base_id: { renderer: :select,
                          options: @packaging_repo.for_select_pallet_bases,
                          disabled_options: @packaging_repo.for_select_inactive_pallet_bases,
                          prompt: true,
                          required: true,
                          caption: 'Pallet Base' },
        pallet_stack_type_id: { renderer: :select,
                                options: @packaging_repo.for_select_pallet_stack_types,
                                disabled_options: @packaging_repo.for_select_inactive_pallet_stack_types,
                                prompt: true,
                                required: true,
                                caption: 'Pallet Stack Type' },
        pallet_format_id: { renderer: :select,
                            options: @packaging_repo.for_select_pallet_formats,
                            disabled_options: @packaging_repo.for_select_inactive_pallet_formats,
                            prompt: true,
                            required: true,
                            caption: 'Pallet Format' },
        pallet_label_name: { renderer: :select,
                             options: MasterfilesApp::LabelTemplateRepo.new.for_select_label_templates(
                               where: { application: AppConst::PRINT_APP_PALLET }
                             ),
                             prompt: true,
                             caption: 'Pallet Label' },
        cartons_per_pallet_id: { renderer: :select,
                                 options: @packaging_repo.for_select_cartons_per_pallet(
                                   where: { pallet_format_id: @form_object.pallet_format_id,
                                            basic_pack_id: @form_object.basic_pack_code_id }
                                 ),
                                 disabled_options: @packaging_repo.for_select_inactive_cartons_per_pallet,
                                 prompt: true,
                                 required: true,
                                 caption: 'Cartons per Pallet' },
        rmt_container_material_owner_id: { renderer: :select,
                                           options: @setup_repo.for_select_rmt_container_material_owners,
                                           caption: 'Rmt Container Material Owner',
                                           prompt: 'Select Rmt Container Material Owner',
                                           searchable: true,
                                           remove_search_for_small_list: false,
                                           hide_on_load: !@requires_material_owner }
      }
    end

    def make_form_object
      @repo = ProductionApp::PackingSpecificationRepo.new
      @packaging_repo = MasterfilesApp::PackagingRepo.new
      @setup_repo = ProductionApp::ProductSetupRepo.new
      apply_form_values

      @requires_material_owner = @setup_repo.requires_material_owner?(@form_object.standard_pack_code_id, @form_object.grade_id)
    end

    def make_header_table
      form_object_merge!(@repo.extend_packing_specification(@form_object))
      compact_header(UtilityFunctions.symbolize_keys(@form_object.compact_header))
    end

    def handle_behaviour
      changed = {
        pallet_stack_type: :pallet_stack_type_changed,
        pallet_format: :pallet_format_changed
      }
      changed = changed[@options[:field]]
      return unhandled_behaviour! if changed.nil?

      send(changed)
    end

    private

    def add_behaviours
      url = "/production/packing_specifications/wizard/change/packing_specification_wizard_packaging/#{@mode}"
      behaviours do |behaviour|
        behaviour.dropdown_change :pallet_stack_type_id,
                                  notify: [{ url: "#{url}/pallet_stack_type",
                                             param_keys: %i[packing_specification_wizard_pallet_base_id] }]
        behaviour.dropdown_change :pallet_format_id,
                                  notify: [{ url: "#{url}/pallet_format" }]
      end
    end

    def pallet_stack_type_changed
      form_object_merge!(params)
      @form_object[:pallet_stack_type_id] = params[:changed_value].to_i
      @form_object[:pallet_base_id] = params[:packing_specification_wizard_pallet_base_id].to_i
      fields = common_fields

      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packing_specification_wizard_pallet_format_id',
                                   options_array: fields[:pallet_format_id][:options])])
    end

    def pallet_format_changed
      form_object_merge!(params)
      @form_object[:pallet_format_id] = params[:changed_value].to_i
      @form_object[:basic_pack_code_id] = params[:basic_pack_code_id].to_i
      fields = common_fields

      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packing_specification_wizard_cartons_per_pallet_id',
                                   options_array: fields[:cartons_per_pallet_id][:options])])
    end
  end
end
