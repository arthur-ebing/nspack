# frozen_string_literal: true

module UiRules
  class ReworksRunRmtBinRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @repo = ProductionApp::ReworksRepo.new
      @delivery_repo = RawMaterialsApp::RmtDeliveryRepo.new
      @container_repo = MasterfilesApp::RmtContainerMaterialTypeRepo.new

      make_form_object
      apply_form_values

      if @mode == :set_rmt_bin_gross_weight
        make_reworks_run_rmt_bin_header_table(%i[farm_code puc_code orchard_code cultivar_name season_code container_type_code
                                                 container_material_type_code qty_bins exit_ref bin_asset_number tipped_asset_number
                                                 qty_inner_bins bin_fullness nett_weight gross_weight bin_tipped bin_received_date_time
                                                 bin_tipped_date_time exit_ref_date_time rebin_created_at scrapped_at scrapped active])
        set_rmt_bin_gross_weight_fields
      end

      if @mode == :edit_rmt_bin
        make_reworks_run_rmt_bin_header_table
        edit_rmt_bin_fields
        edit_rmt_bin_behaviours
      end

      form_name 'reworks_run_rmt_bin'
    end

    def make_reworks_run_rmt_bin_header_table(columns = nil, display_columns = 3)
      compact_header(columns: columns || %i[ farm_code puc_code orchard_code cultivar_name season_code class_code size_code container_type_code
                                             container_material_type_code qty_bins exit_ref bin_asset_number tipped_asset_number
                                             qty_inner_bins bin_fullness nett_weight gross_weight bin_tipped bin_received_date_time
                                             bin_tipped_date_time exit_ref_date_time rebin_created_at scrapped_at scrapped],
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

    def make_form_object
      defaults = { reworks_run_type_id: @options[:reworks_run_type_id],
                   bin_number: @options[:bin_number],
                   measurement_unit: 'KG' }
      @form_object = OpenStruct.new(rmt_bin(@options[:bin_number]).to_h.merge(defaults))
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
      else
        unhandled_behaviour!
      end
    end

    private

    def edit_rmt_bin_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :rmt_container_material_type_id,
                                  notify: [{ url: "/production/reworks/reworks_run_types/#{@options[:reworks_run_type_id]}/reworks_runs/rmt_container_material_type_changed" }]
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
  end
end
