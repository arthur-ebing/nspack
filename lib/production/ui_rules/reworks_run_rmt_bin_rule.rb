# frozen_string_literal: true

module UiRules
  class ReworksRunRmtBinRule < Base
    def generate_rules
      @repo = ProductionApp::ReworksRepo.new
      @delivery_repo = RawMaterialsApp::RmtDeliveryRepo.new
      @container_repo = MasterfilesApp::RmtContainerMaterialTypeRepo.new
      @messcada_repo = MesscadaApp::MesscadaRepo.new

      make_form_object
      apply_form_values

      if @mode == :set_rmt_bin_gross_weight
        make_reworks_run_rmt_bin_header_table(%i[farm_code puc_code orchard_code cultivar_name season_code container_type_code
                                                 container_material_type_code qty_bins exit_ref bin_asset_number tipped_asset_number
                                                 qty_inner_bins bin_fullness nett_weight gross_weight bin_tipped bin_received_date_time
                                                 bin_tipped_date_time exit_ref_date_time rebin_created_at scrapped_at scrapped active shipped_asset_number])
        set_rmt_bin_gross_weight_fields
      end

      if @mode == :edit_rmt_bin
        make_reworks_run_rmt_bin_header_table
        edit_rmt_bin_fields
        edit_rmt_bin_behaviours
      end

      set_rmt_bin_legacy_fields

      form_name 'reworks_run_rmt_bin'
    end

    def make_reworks_run_rmt_bin_header_table(columns = nil, display_columns = 3)
      compact_header(columns: columns || %i[ farm_code puc_code orchard_code cultivar_name season_code class_code size_code container_type_code
                                             container_material_type_code qty_bins exit_ref bin_asset_number tipped_asset_number
                                             qty_inner_bins bin_fullness nett_weight gross_weight bin_tipped bin_received_date_time
                                             bin_tipped_date_time exit_ref_date_time rebin_created_at scrapped_at scrapped shipped_asset_number],
                     display_columns: display_columns,
                     header_captions: {
                       farm_code: 'Farm',
                       puc_code: 'Puc',
                       orchard_code: 'Orchard',
                       cultivar_name: 'Cultivar',
                       season_code: 'Season',
                       container_type_code: 'Container Type',
                       container_material_type_code: 'Container Material Type',
                       size_code: 'Size',
                       class_code: 'Class'
                     })
    end

    def set_rmt_bin_gross_weight_fields
      fields[:bin_number] = { renderer: :hidden }
      fields[:reworks_run_type_id] = { renderer: :hidden }
      fields[:gross_weight] = { renderer: :numeric,
                                required: true,
                                maxvalue: AppConst::MAX_BIN_WEIGHT  }
      fields[:measurement_unit] = { renderer: :hidden }
    end

    def edit_rmt_bin_fields
      fields[:bin_number] = { renderer: :hidden }
      fields[:reworks_run_type_id] = { renderer: :hidden }
      fields[:rmt_class_id] = { renderer: :select,
                                options: MasterfilesApp::FruitRepo.new.for_select_rmt_classes,
                                caption: 'Rmt Class',
                                prompt: true }
      fields[:rmt_size_id] = { renderer: :select,
                               options: MasterfilesApp::RmtSizeRepo.new.for_select_rmt_sizes,
                               caption: 'Size',
                               prompt: true }
      fields[:rmt_container_material_type_id] = { renderer: :select,
                                                  options: @container_repo.for_select_rmt_container_material_types(
                                                    where: { rmt_container_type_id: @form_object.rmt_container_type_id }
                                                  ),
                                                  disabled_options: @container_repo.for_select_inactive_rmt_container_material_types,
                                                  caption: 'Container Material Type',
                                                  prompt: true }
      fields[:rmt_material_owner_party_role_id] = { renderer: :select,
                                                    options: @delivery_repo.find_container_material_owners_by_container_material_type(@form_object.rmt_container_material_type_id),
                                                    caption: 'Container Material Owner',
                                                    prompt: true }
    end

    def set_rmt_bin_legacy_fields # rubocop:disable Metrics/AbcSize
      bin_cultivar = @repo.get(:cultivars, :cultivar_name, @form_object.cultivar_id)
      fields[:colour] = { renderer: :select, options: @messcada_repo.run_treatment_codes, required: true, prompt: true }
      fields[:ripe_point_code] = { renderer: :select, options: @messcada_repo.ripe_point_codes.map { |s| s[0] }.uniq, required: true, prompt: true }
      fields[:pc_code] = { renderer: :select, options: @form_object.pc_code ? [@form_object.pc_code] : [], required: true, prompt: true }
      fields[:cold_store_type] = { renderer: :select, options: %w[CA RA KT NO], required: true, prompt: true }
      fields[:track_slms_indicator_1_code] = { renderer: :select, options: @messcada_repo.track_indicator_codes(bin_cultivar).uniq, required: true, prompt: true }
    end

    def make_form_object
      defaults = { reworks_run_type_id: @options[:reworks_run_type_id],
                   bin_number: @options[:bin_number],
                   measurement_unit: 'KG' }
      attrs = rmt_bin(@options[:bin_number]).to_h.merge(defaults)

      @form_object = OpenStruct.new(attrs)
    end

    def rmt_bin(bin_number)
      bin_id = find_rmt_bin(bin_number)
      @delivery_repo.find_rmt_bin_flat(bin_id)
    end

    def find_rmt_bin(bin_number)
      @repo.find_rmt_bin(bin_number.to_i)
    end

    def handle_behaviour
      case @mode
      when :rmt_container_material_type
        rmt_container_material_type_change
      when :ripe_point_code
        ripe_point_code_change
      else
        unhandled_behaviour!
      end
    end

    private

    def edit_rmt_bin_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :rmt_container_material_type_id,
                                  notify: [{ url: "/production/reworks/reworks_run_types/#{@options[:reworks_run_type_id]}/reworks_runs/rmt_container_material_type_changed" }]
        behaviour.dropdown_change :ripe_point_code, notify: [{ url: "/production/reworks/reworks_run_types/#{@options[:reworks_run_type_id]}/reworks_runs/ripe_point_code_combo_changed" }]
      end
    end

    def rmt_container_material_type_change
      delivery_repo = RawMaterialsApp::RmtDeliveryRepo.new
      container_material_types = if params[:changed_value].blank?
                                   []
                                 else
                                   delivery_repo.find_container_material_owners_by_container_material_type(params[:changed_value])
                                 end
      json_replace_select_options('reworks_run_rmt_bin_rmt_material_owner_party_role_id', container_material_types)
    end

    def ripe_point_code_change
      pc_codes = params[:changed_value].to_s.empty? ? [] : MesscadaApp::MesscadaRepo.new.ripe_point_codes(ripe_point_code: params[:changed_value]).map { |s| s[1] }.uniq
      json_replace_select_options('reworks_run_rmt_bin_pc_code', pc_codes)
    end
  end
end
