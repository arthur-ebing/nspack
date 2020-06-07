# frozen_string_literal: true

module UiRules
  class RebinRule < Base
    def generate_rules
      @repo = ProductionApp::ProductionRunRepo.new
      make_form_object
      apply_form_values

      @rules[:show_nett_weight] = AppConst::DELIVERY_CAPTURE_BIN_WEIGHT_AT_FRUIT_RECEPTION
      @rules[:capture_inner_bins] = AppConst::DELIVERY_CAPTURE_INNER_BINS && !@form_object.rmt_inner_container_type_id.nil?
      @rules[:capture_container_material] = AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL
      @rules[:capture_container_material_owner] = AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER

      common_values_for_fields common_fields

      add_behaviours

      form_name 'rebin'
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
        bin_fullness: { renderer: :select, options: ['Quarter', 'Half', 'Three Quarters', 'Full'], caption: 'Bin Fullness', required: true, prompt: true },
        nett_weight: {},
        rmt_container_material_type_id: { renderer: :select, options: !@form_object.rmt_container_type_id.nil_or_empty? ? MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_rmt_container_material_types(where: { rmt_container_type_id: @form_object.rmt_container_type_id }) : [],
                                          disabled_options: MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_inactive_rmt_container_material_types,
                                          caption: 'Container Material Type', required: true, prompt: true },
        rmt_material_owner_party_role_id: { renderer: :select, options: !@form_object.rmt_container_material_type_id.nil_or_empty? ? RawMaterialsApp::RmtDeliveryRepo.new.find_container_material_owners_by_container_material_type(@form_object.rmt_container_material_type_id) : [], caption: 'Container Material Owner', required: true, prompt: true },
        gross_weight: { caption: 'Avg Gross Weight' }
      }
    end

    def make_form_object
      default_rmt_container_type = RawMaterialsApp::RmtDeliveryRepo.new.rmt_container_type_by_container_type_code(AppConst::DELIVERY_DEFAULT_RMT_CONTAINER_TYPE)
      @form_object = OpenStruct.new(@repo.find_production_run_flat(@options[:production_run_id]).to_h.merge(qty_bins_to_create: nil, rmt_container_type_id: default_rmt_container_type[:id], bin_fullness: :Full))
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :rmt_container_material_type_id, notify: [{ url: '/production/runs/container_material_type_combo_changed' }] if AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL && AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER
      end
    end
  end
end
