# frozen_string_literal: true

module UiRules
  class ReworksRunRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules # rubocop:disable Metrics/AbcSize
      @repo = ProductionApp::ReworksRepo.new
      @quality_repo = MasterfilesApp::QualityRepo.new
      make_form_object
      apply_form_values

      @rules[:show_changes_made] = !@form_object.changes_made.nil_or_empty?
      @rules[:single_pallet_selected] = @form_object.pallets_selected.split("\n").length == 1 unless @form_object.pallets_selected.nil_or_empty?
      @rules[:has_children] = @form_object.has_children
      @rules[:allow_cultivar_group_mixing] = AppConst::CR_PROD.can_mix_cultivar_groups?

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      add_behaviours if %i[new].include? @mode

      form_name 'reworks_run'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      reworks_run_type_id_label = @repo.find_hash(:reworks_run_types, @form_object.reworks_run_type_id)[:run_type]
      @rules[:change_run_details] = [AppConst::RUN_TYPE_CHANGE_RUN_ORCHARD, AppConst::RUN_TYPE_CHANGE_RUN_CULTIVAR].include?(reworks_run_type_id_label)
      if @form_object[:has_children]
        @rules[:change_run_details] ? make_compact_header_table(%i[tipped_bins carton_labels pallet_sequences], 3) : make_compact_header_table
      end
      scrap_reason_id_label = @quality_repo.find_scrap_reason(@form_object.scrap_reason_id)&.scrap_reason
      @rules[:scrap_pallet] = AppConst::RUN_TYPE_SCRAP_PALLET == reworks_run_type_id_label
      @rules[:tip_bins] = AppConst::RUN_TYPE_TIP_BINS == reworks_run_type_id_label
      @rules[:weigh_rmt_bins] = AppConst::RUN_TYPE_WEIGH_RMT_BINS == reworks_run_type_id_label
      @rules[:scrap_bin] = AppConst::RUN_TYPE_SCRAP_BIN == reworks_run_type_id_label
      @rules[:unscrap_bin] = AppConst::RUN_TYPE_UNSCRAP_BIN == reworks_run_type_id_label
      @rules[:bulk_pallet_run_update] = AppConst::RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE == reworks_run_type_id_label
      @rules[:array_of_changes_made] = !@form_object.changes_made_array.nil_or_empty? && !@form_object.changes_made_array.respond_to?(:to_hash)
      @rules[:changes_made_array_count] = @rules[:array_of_changes_made] ? @form_object.changes_made_array.to_a.size : 0
      @rules[:same_pallet_list] = @form_object.pallets_selected.split("\n") == @form_object.pallets_affected.split("\n")
      @rules[:bulk_bin_run_update] = AppConst::RUN_TYPE_BULK_BIN_RUN_UPDATE == reworks_run_type_id_label
      @rules[:bulk_production_run_update] = @rules[:bulk_pallet_run_update] || @rules[:bulk_bin_run_update]
      @rules[:bulk_weigh_bins] = AppConst::RUN_TYPE_BULK_WEIGH_BINS == reworks_run_type_id_label
      @rules[:tip_mixed_orchards] = AppConst::RUN_TYPE_TIP_MIXED_ORCHARDS == reworks_run_type_id_label
      @rules[:restore_repacked_pallet] = AppConst::RUN_TYPE_RESTORE_REPACKED_PALLET == reworks_run_type_id_label
      @rules[:change_bin_delivery] = AppConst::RUN_TYPE_CHANGE_BIN_DELIVERY == reworks_run_type_id_label
      @rules[:single_bin_edit] = AppConst::RUN_TYPE_SINGLE_BIN_EDIT == reworks_run_type_id_label
      @rules[:bin_run_type] = bin_run_type?(reworks_run_type_id_label)
      @rules[:scrap_carton] = AppConst::RUN_TYPE_SCRAP_CARTON == reworks_run_type_id_label
      @rules[:unscrap_carton] = AppConst::RUN_TYPE_UNSCRAP_CARTON == reworks_run_type_id_label
      @rules[:carton_run_type] = carton_run_type?
      @rules[:bulk_update_pallet_dates] = AppConst::RUN_TYPE_BULK_UPDATE_PALLET_DATES == reworks_run_type_id_label

      fields[:created_at] = { renderer: :label,
                              format: :without_timezone_or_seconds }
      fields[:reworks_run_type_id] = { renderer: :label,
                                       with_value: reworks_run_type_id_label,
                                       caption: 'Reworks Run Type' }
      fields[:scrap_reason_id] = { renderer: :label,
                                   with_value: scrap_reason_id_label,
                                   caption: 'Scrap Reason',
                                   hide_on_load: scrapping? ? false : true }
      fields[:remarks] = { renderer: :label,
                           hide_on_load: !@form_object.remarks.nil_or_empty? ? false : true }
      fields[:reworks_action] = { renderer: :label,
                                  hide_on_load: !@form_object.reworks_action.nil_or_empty? ? false : true }
      fields[:user] = { renderer: :label }
      fields[:pallets_selected] = { renderer: :list,
                                    items: @form_object.pallets_selected.split("\n"),
                                    scroll_height: :short,
                                    filled_background: true,
                                    caption: "Selected #{text_area_caption}",
                                    hide_on_load: @rules[:single_pallet_selected] || @rules[:same_pallet_list] ? true : false }
      fields[:pallets_affected] = if @rules[:single_pallet_selected]
                                    { renderer: :label,
                                      with_value: @form_object.pallets_affected,
                                      caption: "Affected #{text_area_caption}" }
                                  else
                                    { renderer: :list,
                                      items: @form_object.pallets_affected.split("\n"),
                                      scroll_height: :short,
                                      filled_background: true,
                                      caption: "Affected #{text_area_caption}" }
                                  end
      fields[:pallet_number] = { renderer: :label,
                                 hide_on_load: !@form_object.pallet_number.nil_or_empty? ? false : true }
      fields[:pallet_sequence_number] = { renderer: :label,
                                          hide_on_load: !@form_object.pallet_sequence_number.nil_or_empty? ? false : true }
      fields[:allow_cultivar_mixing] = { renderer: :label,
                                         as_boolean: true }
      fields[:allow_cultivar_group_mixing] = { renderer: :label,
                                               as_boolean: true,
                                               hide_on_load: @rules[:allow_cultivar_group_mixing] ? false : true }

      if @rules[:array_of_changes_made]
        @form_object.changes_made_array.to_a.each_with_index do |change, i|
          left_record = change['change_descriptions'].nil_or_empty? ? change['before'] : change['change_descriptions']['before']
          right_record = change['change_descriptions'].nil_or_empty? ? change['after'] : change['change_descriptions']['after']
          fields["changes_made_#{i}".to_sym] = {
            no_padding: true,
            left_caption: 'Before',
            right_caption: 'After',
            left_record: left_record.sort.to_h,
            right_record: right_record.sort.to_h
          }
        end
      else
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
        fields[:changes_made] = {
          no_padding: true,
          left_caption: 'Before',
          right_caption: 'After',
          left_record: left_record.transform_values { |v| UtilityFunctions.scientific_notation_to_s(v) }.sort.to_h,
          right_record: right_record.transform_values { |v| UtilityFunctions.scientific_notation_to_s(v) }.sort.to_h
        }
      end
    end

    def common_fields # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      reworks_run_type_id_label = @form_object.reworks_run_type_id.nil_or_empty? ? '' : @repo.find_hash(:reworks_run_types, @form_object.reworks_run_type_id)[:run_type]
      @rules[:scrap_pallet] = AppConst::RUN_TYPE_SCRAP_PALLET == reworks_run_type_id_label
      @rules[:scrap_bin] = AppConst::RUN_TYPE_SCRAP_BIN == reworks_run_type_id_label
      @rules[:unscrap_bin] = AppConst::RUN_TYPE_UNSCRAP_BIN == reworks_run_type_id_label
      @rules[:single_pallet_edit] = AppConst::RUN_TYPE_SINGLE_PALLET_EDIT == reworks_run_type_id_label
      @rules[:single_bin_edit] = AppConst::RUN_TYPE_SINGLE_BIN_EDIT == reworks_run_type_id_label
      @rules[:unscrap_pallet] = AppConst::RUN_TYPE_UNSCRAP_PALLET == reworks_run_type_id_label
      @rules[:tip_bins] = AppConst::RUN_TYPE_TIP_BINS == reworks_run_type_id_label
      @rules[:weigh_rmt_bins] = AppConst::RUN_TYPE_WEIGH_RMT_BINS == reworks_run_type_id_label
      @rules[:bulk_pallet_run_update] = AppConst::RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE == reworks_run_type_id_label
      @rules[:single_edit] = @rules[:single_pallet_edit] || @rules[:weigh_rmt_bins] || @rules[:single_bin_edit]
      @rules[:bulk_bin_run_update] = AppConst::RUN_TYPE_BULK_BIN_RUN_UPDATE == reworks_run_type_id_label
      @rules[:bulk_production_run_update] = @rules[:bulk_pallet_run_update] || @rules[:bulk_bin_run_update]
      @rules[:bulk_weigh_bins] = AppConst::RUN_TYPE_BULK_WEIGH_BINS == reworks_run_type_id_label
      @rules[:untip_bins] = AppConst::RUN_TYPE_UNTIP_BINS == reworks_run_type_id_label
      @rules[:tip_mixed_orchards] = AppConst::RUN_TYPE_TIP_MIXED_ORCHARDS == reworks_run_type_id_label
      @rules[:restore_repacked_pallet] = AppConst::RUN_TYPE_RESTORE_REPACKED_PALLET == reworks_run_type_id_label
      @rules[:change_bin_delivery] = AppConst::RUN_TYPE_CHANGE_BIN_DELIVERY == reworks_run_type_id_label
      @rules[:bin_run_type] = bin_run_type?(reworks_run_type_id_label)
      @rules[:scrap_carton] = AppConst::RUN_TYPE_SCRAP_CARTON == reworks_run_type_id_label
      @rules[:unscrap_carton] = AppConst::RUN_TYPE_UNSCRAP_CARTON == reworks_run_type_id_label
      @rules[:carton_run_type] = carton_run_type?
      @rules[:show_allow_cultivar_group_mixing] = @rules[:allow_cultivar_group_mixing] && @rules[:bulk_production_run_update]
      @rules[:bulk_update_pallet_dates] = AppConst::RUN_TYPE_BULK_UPDATE_PALLET_DATES == reworks_run_type_id_label

      text_caption = if @rules[:single_pallet_edit]
                       'Pallet Number'
                     else
                       'Bin'
                     end

      where = if @rules[:scrap_bin]
                { applies_to_bins: true }
              elsif @rules[:scrap_carton]
                { applies_to_cartons: true }
              else
                { applies_to_pallets: true }
              end
      {
        reworks_run_type_id: { renderer: :hidden },
        reworks_run_type: { renderer: :label,
                            with_value: reworks_run_type_id_label,
                            caption: 'Reworks Run Type' },
        scrap_reason_id: { renderer: :select,
                           options: @quality_repo.for_select_scrap_reasons(where: where),
                           disabled_options: @quality_repo.for_select_inactive_scrap_reasons,
                           caption: 'Scrap Reason',
                           hide_on_load: scrapping? ? false : true },
        remarks: { renderer: :textarea,
                   rows: 5,
                   placeholder: 'Scrap remarks',
                   caption: 'Scrap Remarks',
                   hide_on_load: scrapping? ? false : true },
        pallets_selected: if @rules[:single_edit]
                            { caption: text_caption }
                          else
                            { renderer: :textarea,
                              rows: 12,
                              placeholder: "Paste #{text_area_caption} here",
                              caption: text_area_caption }
                          end,
        production_run_id: { renderer: :integer,
                             required: @rules[:tip_bins] || @rules[:tip_mixed_orchards],
                             caption: 'Production Run Id',
                             hide_on_load: @rules[:tip_bins] || @rules[:tip_mixed_orchards] ? false : true },
        allow_cultivar_mixing: { renderer: :checkbox,
                                 hide_on_load: @rules[:tip_bins] ? false : true },
        from_production_run_id: { renderer: :integer,
                                  required: @rules[:bulk_production_run_update],
                                  caption: 'From Production Run',
                                  hide_on_load: @rules[:bulk_production_run_update] ? false : true },
        to_production_run_id: { renderer: :integer,
                                required: @rules[:bulk_production_run_update],
                                caption: 'To Production Run',
                                hide_on_load: @rules[:bulk_production_run_update] ? false : true },
        pallet_number: { renderer: :input,
                         subtype: :integer,
                         required: true },
        gross_weight: { renderer: :numeric,
                        caption: @rules[:tip_bins] || @rules[:tip_mixed_orchards] ? 'Average Gross Weight' : 'Gross Weight',
                        hide_on_load: @rules[:bulk_weigh_bins] || @rules[:tip_bins] || @rules[:tip_mixed_orchards] ? false : true,
                        maxvalue: AppConst::MAX_BIN_WEIGHT  },
        avg_gross_weight: { renderer: :checkbox,
                            hide_on_load: @rules[:bulk_weigh_bins] ? false : true },
        allow_cultivar_group_mixing: { renderer: :checkbox,
                                       hide_on_load: @rules[:show_allow_cultivar_group_mixing] ? false : true },
        first_cold_storage_at: { renderer: :input,
                                 subtype: :date,
                                 required: true,
                                 hide_on_load: @rules[:bulk_update_pallet_dates] ? false : true }
      }
    end

    def make_form_object
      if %i[new search].include? @mode
        make_new_form_object
        return
      end

      hash = @repo.find_reworks_run(@options[:id]).to_h
      hash = hash.merge(make_compact_details(hash[:reworks_run_type_id], hash[:pallets_affected])) if hash[:has_children]

      @form_object = OpenStruct.new(hash)
    end

    def make_new_form_object
      @form_object = OpenStruct.new(reworks_run_type_id: @options[:reworks_run_type_id],
                                    remarks: nil,
                                    scrap_reason_id: nil,
                                    pallets_selected: nil,
                                    production_run_id: nil,
                                    allow_cultivar_mixing: true)
    end

    def bin_run_type?(reworks_run_type)
      AppConst::REWORKS_RUN_NON_PALLET_RUNS[reworks_run_type] == :bin
    end

    def carton_run_type?
      @rules[:scrap_carton] || @rules[:unscrap_carton]
    end

    def scrapping?
      @rules[:scrap_pallet] || @rules[:scrap_bin] || @rules[:scrap_carton]
    end

    def text_area_caption
      if @rules[:bin_run_type]
        'Bins'
      elsif @rules[:carton_run_type]
        'Cartons'
      else
        'Pallets'
      end
    end

    def make_compact_details(reworks_run_type_id, affected_ids)
      affected_ids = affected_ids.split("\n").map(&:strip).reject(&:empty?)
      reworks_run_type = @repo.find_hash(:reworks_run_types, reworks_run_type_id)[:run_type]
      change_run_details = [AppConst::RUN_TYPE_CHANGE_RUN_ORCHARD, AppConst::RUN_TYPE_CHANGE_RUN_CULTIVAR].include?(reworks_run_type)
      change_run_details ? production_run_compact_details(affected_ids) : delivery_compact_details(affected_ids)
    end

    def delivery_compact_details(affected_delivery_ids)
      res = @repo.change_objects_counts(affected_delivery_ids)
      { deliveries: res[:deliveries],
        production_runs: res[:production_runs],
        tipped_bins: res[:tipped_bins],
        carton_labels: res[:carton_labels],
        cartons: res[:cartons],
        pallet_sequences: res[:pallet_sequences],
        shipped_pallet_sequences: res[:shipped_pallet_sequences],
        inspected_pallet_sequences: res[:inspected_pallet_sequences] }
    end

    def production_run_compact_details(affected_run_ids)
      res = @repo.production_run_objects(affected_run_ids)
      { tipped_bins: res[:tipped_bin_ids].nil_or_empty? ? 0 : res[:tipped_bin_ids].count,
        carton_labels: res[:carton_label_ids].nil_or_empty? ? 0 : res[:carton_label_ids].count,
        pallet_sequences: res[:pallet_sequence_ids].nil_or_empty? ? 0 : res[:pallet_sequence_ids].count }
    end

    def make_compact_header_table(columns = nil, display_columns = 2)
      compact_header(columns: columns || %i[deliveries production_runs tipped_bins carton_labels cartons pallet_sequences
                                            shipped_pallet_sequences inspected_pallet_sequences],
                     display_columns: display_columns)
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.keyup :production_run_id,
                        notify: [{ url: "/production/reworks/reworks_run_types/#{@options[:reworks_run_type_id]}/reworks_runs/production_run_id_changed",
                                   param_keys: %i[reworks_run_allow_cultivar_mixing] }]
        behaviour.input_change :allow_cultivar_mixing,
                               notify: [{ url: "/production/reworks/reworks_run_types/#{@options[:reworks_run_type_id]}/reworks_runs/allow_cultivar_mixing_changed",
                                          param_keys: %i[reworks_run_production_run_id] }]
      end
    end
  end
end
