# frozen_string_literal: true

module UiRules
  class RebinRule < Base
    def generate_rules
      @repo = ProductionApp::ProductionRunRepo.new
      @print_repo = LabelApp::PrinterRepo.new
      @template_repo = MasterfilesApp::LabelTemplateRepo.new

      make_form_object
      apply_form_values

      @rules[:show_nett_weight] = AppConst::DELIVERY_CAPTURE_BIN_WEIGHT_AT_FRUIT_RECEPTION
      @rules[:capture_inner_bins] = AppConst::DELIVERY_CAPTURE_INNER_BINS && !@form_object.rmt_inner_container_type_id.nil?
      # @rules[:capture_container_material] = AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL
      @rules[:capture_container_material_owner] = AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER

      common_values_for_fields common_fields

      set_print_rebin_labels_fields if @mode == :print_rebin_labels

      add_behaviours

      form_name 'rebin'
    end

    def set_print_rebin_labels_fields
      fields[:printer] = { renderer: :select,
                           options: @print_repo.select_printers_for_application(AppConst::PRINT_APP_REBIN),
                           required: true }
      fields[:label_template_id] = { renderer: :select,
                                     options: @template_repo.for_select_label_templates(where: { application: AppConst::PRINT_APP_BIN }),
                                     required: true }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      {
        qty_bins_to_create: { required: true },
        rmt_class_id: { renderer: :select, options: MasterfilesApp::FruitRepo.new.for_select_rmt_classes,
                        required: true, prompt: true },
        farm_code: { renderer: :label },
        puc_code: { renderer: :label },
        orchard_code: { renderer: :label },
        cultivar_name: { renderer: :label },
        cultivar_group_code: { renderer: :label },
        season_code: { renderer: :label },
        bin_fullness: { renderer: :select, options: AppConst::BIN_FULLNESS_OPTIONS, caption: 'Bin Fullness', required: true, prompt: true },
        nett_weight: {},
        rmt_container_material_type_id: { renderer: :select, options: !@form_object.rmt_container_type_id.nil_or_empty? ? MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_rmt_container_material_types(where: { rmt_container_type_id: @form_object.rmt_container_type_id }) : [],
                                          disabled_options: MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_inactive_rmt_container_material_types,
                                          caption: 'Container Material Type', required: true, prompt: true },
        rmt_material_owner_party_role_id: { renderer: :select, options: !@form_object.rmt_container_material_type_id.nil_or_empty? ? RawMaterialsApp::RmtDeliveryRepo.new.find_container_material_owners_by_container_material_type(@form_object.rmt_container_material_type_id) : [], caption: 'Container Material Owner', required: true, prompt: true },
        gross_weight: { caption: 'Avg Gross Weight' },
        rmt_size_id: { renderer: :select,
                       options: MasterfilesApp::RmtSizeRepo.new.for_select_rmt_sizes,
                       prompt: true }

      }
    end

    def make_form_object
      if @mode == :print_rebin_labels
        @form_object = OpenStruct.new(printer: @print_repo.default_printer_for_application(AppConst::PRINT_APP_REBIN),
                                      label_template_id: nil)
        return
      end

      default_rmt_container_type = RawMaterialsApp::RmtDeliveryRepo.new.rmt_container_type_by_container_type_code(AppConst::DEFAULT_RMT_CONTAINER_TYPE)
      @form_object = OpenStruct.new(@repo.find_production_run_flat(@options[:production_run_id]).to_h.merge(qty_bins_to_create: nil,
                                                                                                            rmt_container_type_id: default_rmt_container_type[:id],
                                                                                                            bin_fullness: AppConst::BIN_FULL,
                                                                                                            rmt_size_id: nil))
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :rmt_container_material_type_id, notify: [{ url: '/production/runs/container_material_type_combo_changed' }] if AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER
      end
    end
  end
end
