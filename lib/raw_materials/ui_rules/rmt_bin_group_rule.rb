# frozen_string_literal: true

module UiRules
  class RmtBinGroupRule < Base
    def generate_rules # rubocop:disable Metrics/AbcSize
      @repo = RawMaterialsApp::RmtDeliveryRepo.new
      @print_repo = LabelApp::PrinterRepo.new
      @delivery = if @options[:delivery_id].nil?
                    @repo.find_rmt_delivery_by_bin_id(@options[:id])
                  else
                    @repo.get_bin_delivery(@options[:delivery_id])
                  end

      make_form_object
      apply_form_values

      @rules[:show_nett_weight] = AppConst::DELIVERY_CAPTURE_BIN_WEIGHT_AT_FRUIT_RECEPTION
      @rules[:capture_inner_bins] = AppConst::DELIVERY_CAPTURE_INNER_BINS && !@form_object.rmt_inner_container_type_id.nil?
      @rules[:capture_container_material] = AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL
      @rules[:capture_container_material_owner] = AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER

      compact_header(columns: %i[farm_code puc_code orchard_code date_picked date_delivered qty_bins_tipped qty_bins_received], display_columns: 1) if @mode == :new

      common_values_for_fields common_fields

      add_behaviours if %i[new edit].include? @mode

      form_name 'rmt_bin'
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      {
        bin_asset_number: { renderer: :label },
        # qty_bins: { required: true },
        bin_fullness: { renderer: :select, options: ['Quarter', 'Half', 'Three Quarters', 'Full'], caption: 'Bin Fullness', required: true, prompt: true },
        nett_weight: {},
        rmt_container_type_id: { renderer: :select, options: MasterfilesApp::RmtContainerTypeRepo.new.for_select_rmt_container_types, required: true, prompt: true },
        rmt_class_id: { renderer: :select, options: MasterfilesApp::FruitRepo.new.for_select_rmt_classes, required: true, prompt: true },
        rmt_container_material_type_id: { renderer: :select, options: !@form_object.rmt_container_type_id.nil_or_empty? ? MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_rmt_container_material_types(where: { rmt_container_type_id: @form_object.rmt_container_type_id }) : [],
                                          disabled_options: MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_inactive_rmt_container_material_types,
                                          caption: 'Container Material Type', required: true, prompt: true },
        rmt_material_owner_party_role_id: { renderer: :select, options: !@form_object.rmt_container_material_type_id.nil_or_empty? ? @repo.find_container_material_owners_by_container_material_type(@form_object.rmt_container_material_type_id) : [], caption: 'Container Material Owner', required: true, prompt: true },
        # qty_inner_bins: { renderer: :integer, hide_on_load: @rules[:capture_inner_bins] ? false : true }
        qty_bins_to_create: { required: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_rmt_bin(@options[:id])
      # @form_object = OpenStruct.new(@form_object.to_h.merge(printer: @print_repo.default_printer_for_application(AppConst::PRINT_APP_BIN), no_of_prints: 1)) if @mode == :print_barcode
    end

    def make_new_form_object
      @default_rmt_container_type = @repo.rmt_container_type_by_container_type_code(AppConst::DELIVERY_DEFAULT_RMT_CONTAINER_TYPE)
      @form_object = OpenStruct.new(rmt_delivery_id: nil,
                                    season_id: nil,
                                    cultivar_id: @delivery[:cultivar_id],
                                    orchard_id: @delivery[:orchard_id],
                                    farm_code: @delivery[:farm_code],
                                    puc_code: @delivery[:puc_code],
                                    orchard_code: @delivery[:orchard_code],
                                    date_picked: @delivery[:date_picked],
                                    date_delivered: @delivery[:date_delivered],
                                    qty_bins_received: @delivery[:qty_bins_received],
                                    qty_bins_tipped: @delivery[:qty_bins_tipped],
                                    farm_id: nil,
                                    rmt_class_id: nil,
                                    rmt_material_owner_party_role_id: nil,
                                    rmt_container_type_id: (@default_rmt_container_type || {})[:id],
                                    rmt_container_material_type_id: nil,
                                    cultivar_group_id: nil,
                                    puc_id: nil,
                                    status: nil,
                                    exit_ref: nil,
                                    qty_bins: 1,
                                    bin_asset_number: nil,
                                    tipped_asset_number: nil,
                                    rmt_inner_container_type_id: (@default_rmt_container_type || {})[:rmt_inner_container_type_id],
                                    rmt_inner_container_material_id: nil,
                                    qty_inner_bins: nil,
                                    production_run_rebin_id: nil,
                                    production_run_tipped_id: nil,
                                    bin_tipping_plant_resource_id: nil,
                                    bin_fullness: 'Full',
                                    nett_weight: nil,
                                    gross_weight: nil,
                                    bin_tipped: nil,
                                    bin_received_date_time: nil,
                                    bin_tipped_date_time: nil,
                                    exit_ref_date_time: nil,
                                    rebin_created_at: nil,
                                    scrapped: nil,
                                    scrapped_at: nil)
    end

    # private

    def add_behaviours
      return unless AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL

      behaviours do |behaviour|
        behaviour.dropdown_change :rmt_container_type_id, notify: [{ url: '/raw_materials/deliveries/rmt_bins/rmt_container_type_combo_changed' }]
        behaviour.dropdown_change :rmt_container_material_type_id, notify: [{ url: '/raw_materials/deliveries/rmt_bins/container_material_type_combo_changed', param_keys: %i[rmt_bin_rmt_container_material_type_id] }] if AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER
      end
    end
  end
end
