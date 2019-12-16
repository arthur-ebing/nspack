# frozen_string_literal: true

module UiRules
  class ReworksRunRmtBinRule < Base
    def generate_rules
      @repo = ProductionApp::ReworksRepo.new

      make_form_object
      apply_form_values

      @rules[:scan_rmt_bin_asset_numbers] = AppConst::USE_PERMANENT_RMT_BIN_BARCODES

      if @mode == :set_rmt_bin_gross_weight
        make_reworks_run_rmt_bin_header_table
        set_rmt_bin_gross_weight_fields
      end

      form_name 'reworks_run_rmt_bin'
    end

    def make_reworks_run_rmt_bin_header_table(columns = nil, display_columns = 3)
      compact_header(columns: columns || %i[ farm_code puc_code orchard_code cultivar_name season_code container_type_code
                                             container_material_type_code qty_bins exit_refbin_asset_number tipped_asset_number
                                             qty_inner_bins bin_fullness nett_weight gross_weight bin_tipped bin_received_date_time
                                             bin_tipped_date_time exit_ref_date_time rebin_created_at scrapped_at scrapped active],
                     display_columns: display_columns,
                     header_captions: {
                       first_cold_storage_at: 'Cold Storage Date',
                       govt_first_inspection_at: 'Inspection At',
                       govt_reinspection_at: 'Reinspection At',
                       marketing_variety: 'Variety'
                     })
    end

    def set_rmt_bin_gross_weight_fields
      fields[:bin_number] = { renderer: :hidden }
      fields[:reworks_run_type_id] = { renderer: :hidden }
      fields[:gross_weight] = { renderer: :numeric,
                                required: true }
      fields[:measurement_unit] = { renderer: :hidden }
    end

    def make_form_object
      defaults = { reworks_run_type_id: @options[:reworks_run_type_id],
                   bin_number: @options[:bin_number],
                   measurement_unit: 'KG' }
      @form_object = OpenStruct.new(rmt_bin(@options[:bin_number]).to_h.merge(defaults))
    end

    def rmt_bin(bin_number)
      bin_id = find_rmt_bin(bin_number)
      RawMaterialsApp::RmtDeliveryRepo.new.find_rmt_bin_flat(bin_id)
    end

    def find_rmt_bin(bin_number)
      return @repo.rmt_bin_from_asset_number(bin_number) if AppConst::USE_PERMANENT_RMT_BIN_BARCODES

      @repo.find_rmt_bin(bin_number.to_i)
    end
  end
end
