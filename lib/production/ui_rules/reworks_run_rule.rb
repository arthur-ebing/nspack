# frozen_string_literal: true

module UiRules
  class ReworksRunRule < Base # rubocop:disable ClassLength
    def generate_rules  # rubocop:disable Metrics/AbcSize
      @repo = ProductionApp::ReworksRepo.new
      make_form_object
      apply_form_values

      @rules[:show_changes_made] = !@form_object.changes_made.nil_or_empty?
      @rules[:single_pallet_selected] = @form_object.pallets_selected.split("\n").length == 1 unless @form_object.pallets_selected.nil_or_empty?
      @rules[:scan_rmt_bin_asset_numbers] = AppConst::USE_PERMANENT_RMT_BIN_BARCODES

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'reworks_run'
    end

    def set_show_fields  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      reworks_run_type_id_label = @repo.find_hash(:reworks_run_types, @form_object.reworks_run_type_id)[:run_type]
      scrap_reason_id_label = MasterfilesApp::QualityRepo.new.find_scrap_reason(@form_object.scrap_reason_id)&.scrap_reason
      @rules[:scrap_pallet] = AppConst::RUN_TYPE_SCRAP_PALLET == reworks_run_type_id_label
      @rules[:tip_bins] = AppConst::RUN_TYPE_TIP_BINS == reworks_run_type_id_label
      @rules[:weigh_rmt_bins] = AppConst::RUN_TYPE_WEIGH_RMT_BINS == reworks_run_type_id_label

      text_area_caption = @rules[:tip_bins] || @rules[:weigh_rmt_bins] ? 'Bins' : 'Pallet Numbers'

      left_record = if @form_object.before_state.nil_or_empty?
                      { id: nil }
                    else
                      @form_object.before_descriptions_state.nil_or_empty? ? @form_object.before_state : @form_object.before_descriptions_state
                    end

      right_record = if @form_object.after_state.nil_or_empty?
                       { id: nil }
                     else
                       @form_object.after_descriptions_state.nil_or_empty? ? @form_object.after_state : @form_object.after_descriptions_state
                     end
      fields[:reworks_run_type_id] = { renderer: :label,
                                       with_value: reworks_run_type_id_label,
                                       caption: 'Reworks Run Type' }
      fields[:scrap_reason_id] = { renderer: :label,
                                   with_value: scrap_reason_id_label,
                                   caption: 'Scrap Reason',
                                   hide_on_load: @rules[:scrap_pallet] ? false : true }
      fields[:remarks] = { renderer: :label,
                           hide_on_load: @rules[:scrap_pallet] ? false : true }
      fields[:reworks_action] = { renderer: :label,
                                  hide_on_load: !@form_object.reworks_action.nil_or_empty? ? false : true }
      fields[:user] = { renderer: :label }
      fields[:pallets_selected] = { renderer: :textarea,
                                    rows: 10,
                                    disabled: true,
                                    caption: "Selected #{text_area_caption}",
                                    hide_on_load: @rules[:single_pallet_selected] ? true : false }
      fields[:pallets_affected] = if @rules[:single_pallet_selected]
                                    { renderer: :label,
                                      with_value: @form_object.pallets_affected,
                                      caption: "Affected #{text_area_caption}" }
                                  else
                                    { renderer: :textarea,
                                      rows: 10,
                                      disabled: true,
                                      caption: "Affected #{text_area_caption}" }
                                  end
      fields[:pallet_number] = { renderer: :label,
                                 hide_on_load: !@form_object.pallet_number.nil_or_empty? ? false : true }
      fields[:pallet_sequence_number] = { renderer: :label,
                                          hide_on_load: !@form_object.pallet_sequence_number.nil_or_empty? ? false : true }
      fields[:changes_made] = {
        left_caption: 'Before',
        right_caption: 'After',
        left_record: left_record.sort.to_h,
        right_record: right_record.sort.to_h
      }
    end

    def common_fields  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      reworks_run_type_id_label = @repo.find_hash(:reworks_run_types, @form_object.reworks_run_type_id)[:run_type]
      @rules[:scrap_pallet] = AppConst::RUN_TYPE_SCRAP_PALLET == reworks_run_type_id_label
      @rules[:single_pallet_edit] = AppConst::RUN_TYPE_SINGLE_PALLET_EDIT == reworks_run_type_id_label
      @rules[:unscrap_pallet] = AppConst::RUN_TYPE_UNSCRAP_PALLET == reworks_run_type_id_label
      @rules[:tip_bins] = AppConst::RUN_TYPE_TIP_BINS == reworks_run_type_id_label
      @rules[:weigh_rmt_bins] = AppConst::RUN_TYPE_WEIGH_RMT_BINS == reworks_run_type_id_label
      @rules[:single_edit] = @rules[:single_pallet_edit] || @rules[:weigh_rmt_bins]

      text_caption = if @rules[:single_pallet_edit]
                       'Pallet Number'
                     else
                       'Bin' # @rules[:scan_rmt_bin_asset_numbers] ? 'Bin asset number' : 'Bin id'
                     end
      text_area_caption = @rules[:tip_bins] || @rules[:weigh_rmt_bins] ? 'Bins' : 'Pallet Numbers'
      {
        reworks_run_type_id: { renderer: :hidden },
        reworks_run_type: { renderer: :label,
                            with_value: reworks_run_type_id_label,
                            caption: 'Reworks Run Type' },
        scrap_reason_id: { renderer: :select,
                           options: MasterfilesApp::QualityRepo.new.for_select_scrap_reasons(where: :applies_to_pallets),
                           disabled_options: MasterfilesApp::QualityRepo.new.for_select_inactive_scrap_reasons,
                           caption: 'Scrap Reason',
                           hide_on_load: @rules[:scrap_pallet] ? false : true },
        remarks: { renderer: :textarea,
                   rows: 5,
                   placeholder: 'Scrap remarks',
                   caption: 'Scrap Remarks',
                   hide_on_load: @rules[:scrap_pallet] ? false : true },
        pallets_selected: if @rules[:single_edit]
                            { caption: text_caption }
                          else
                            { renderer: :textarea,
                              rows: 12,
                              placeholder: "Paste #{text_area_caption} here",
                              caption: text_area_caption }
                          end,
        production_run_id: { renderer: :select,
                             options: ProductionApp::ReworksRepo.new.for_select_open_production_runs,
                             caption: 'Production Runs',
                             prompt: 'Select Production Run',
                             sort_items: false,
                             remove_search_for_small_list: false,
                             hide_on_load: @rules[:tip_bins] ? false : true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_reworks_run(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(reworks_run_type_id: @options[:reworks_run_type_id],
                                    remarks: nil,
                                    scrap_reason_id: nil,
                                    pallets_selected: nil,
                                    production_run_id: nil)
    end
  end
end
