# frozen_string_literal: true

module UiRules
  class GrowerGradingRuleItemRule < Base
    def generate_rules # rubocop:disable Metrics/AbcSize
      @repo = ProductionApp::GrowerGradingRepo.new
      @fruit_repo = MasterfilesApp::FruitRepo.new
      @fruit_size_repo = MasterfilesApp::FruitSizeRepo.new

      make_form_object

      @rules[:rebin_rule] = @repo.get(:grower_grading_rules, @form_object.grower_grading_rule_id, :rebin_rule)
      @rules[:legacy_data_fields] = AppConst::CR_PROD.grower_grading_json_fields[:legacy_data]
      @rules[:rule_item_changes_fields] = @repo.grower_grading_rule_changes(@form_object.grower_grading_rule_id)
      @rules[:show_legacy_data_fields] = !@rules[:legacy_data_fields].empty?
      @rules[:show_rule_item_changes_fields] = !@rules[:rule_item_changes_fields].empty?

      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      add_behaviours if %i[new edit clone].include? @mode

      form_name 'grower_grading_rule_item'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      grower_grading_rule_id_label = @repo.get(:grower_grading_rules, @form_object.grower_grading_rule_id, :rule_name)
      commodity_id_label = @repo.get(:commodities, @form_object.commodity_id, :code)
      grade_id_label = @repo.get(:grades, @form_object.grade_id, :grade_code)
      std_fruit_size_count_id_label = @repo.get(:std_fruit_size_counts, @form_object.std_fruit_size_count_id, :size_count_value)
      fruit_actual_counts_for_pack_id_label = @repo.get(:fruit_actual_counts_for_packs, @form_object.fruit_actual_counts_for_pack_id, :actual_count_for_pack)
      marketing_variety_id_label = @repo.get(:marketing_varieties, @form_object.marketing_variety_id, :marketing_variety_code)
      fruit_size_reference_id_label = @repo.get(:fruit_size_references, @form_object.fruit_size_reference_id, :size_reference)
      rmt_class_id_label = @repo.get(:rmt_classes, @form_object.rmt_class_id, :rmt_class_code)
      rmt_size_id_label = @repo.get(:rmt_sizes, @form_object.rmt_size_id, :size_code)
      inspection_type_id_label = @repo.get(:inspection_types, @form_object.inspection_type_id, :inspection_type_code)
      fields[:grower_grading_rule_id] = { renderer: :label,
                                          with_value: grower_grading_rule_id_label,
                                          caption: 'Grading Rule' }
      fields[:commodity_id] = { renderer: :label,
                                with_value: commodity_id_label,
                                caption: 'Commodity' }
      fields[:grade_id] = { renderer: :label,
                            hide_on_load: @rules[:rebin_rule],
                            with_value: grade_id_label,
                            caption: 'Grade' }
      fields[:std_fruit_size_count_id] = { renderer: :label,
                                           hide_on_load: @rules[:rebin_rule],
                                           with_value: std_fruit_size_count_id_label,
                                           caption: 'Size Count' }
      fields[:fruit_actual_counts_for_pack_id] = { renderer: :label,
                                                   hide_on_load: @rules[:rebin_rule],
                                                   with_value: fruit_actual_counts_for_pack_id_label,
                                                   caption: 'Actual Count' }
      fields[:marketing_variety_id] = { renderer: :label,
                                        with_value: marketing_variety_id_label,
                                        caption: 'Marketing Variety' }
      fields[:fruit_size_reference_id] = { renderer: :label,
                                           hide_on_load: @rules[:rebin_rule],
                                           with_value: fruit_size_reference_id_label,
                                           caption: 'Size Reference' }
      fields[:rmt_class_id] = { renderer: :label,
                                with_value: rmt_class_id_label,
                                caption: 'Rmt Class' }
      fields[:rmt_size_id] = { renderer: :label,
                               hide_on_load: !@rules[:rebin_rule],
                               with_value: rmt_size_id_label,
                               caption: 'Rmt Size' }
      fields[:inspection_type_id] = { renderer: :label,
                                      with_value: inspection_type_id_label,
                                      caption: 'Inspection Type' }
      fields[:active] = { renderer: :label,
                          as_boolean: true }
      fields[:created_by] = { renderer: :label }
      fields[:updated_by] = { renderer: :label }

      if @rules[:show_legacy_data_fields]
        @rules[:legacy_data_fields].each do |v|
          fields[v.to_sym] = { renderer: :label,
                               caption: v.to_s,
                               with_value: @form_object.legacy_data.to_h[v.to_s]  }
        end
      end

      return fields unless @rules[:show_rule_item_changes_fields]

      graded_rmt_class_id_label = @form_object.changes.to_h['rmt_class_id'].nil_or_empty? ? '' : @repo.get(:rmt_classes, @form_object.changes.to_h['rmt_class_id'], :rmt_class_code)
      graded_rmt_size_id_label = @form_object.changes.to_h['rmt_size_id'].nil_or_empty? ? '' : @repo.get(:rmt_sizes, @form_object.changes.to_h['rmt_size_id'], :size_code)
      graded_grade_id_label = @form_object.changes.to_h['grade_id'].nil_or_empty? ? '' : @repo.get(:grades, @form_object.changes.to_h['grade_id'], :grade_code)
      graded_size_count_id_label = @form_object.changes.to_h['std_fruit_size_count_id'].nil_or_empty? ? '' : @repo.get(:std_fruit_size_counts, @form_object.changes.to_h['std_fruit_size_count_id'], :size_count_value)
      fields[:graded_rmt_class_id] = { renderer: :label,
                                       caption: 'Graded Rmt Class',
                                       with_value: graded_rmt_class_id_label }
      fields[:graded_rmt_size_id] = { renderer: :label,
                                      caption: 'Graded Rmt Size',
                                      invisible: !@rules[:rebin_rule],
                                      with_value: graded_rmt_size_id_label }
      fields[:graded_grade_id] = { renderer: :label,
                                   caption: 'Graded Grade',
                                   invisible: @rules[:rebin_rule],
                                   with_value: graded_grade_id_label }
      fields[:graded_std_fruit_size_count_id] = { renderer: :label,
                                                  caption: 'Graded Size Count',
                                                  invisible: @rules[:rebin_rule],
                                                  with_value: graded_size_count_id_label }
      fields[:graded_gross_weight] = { renderer: :label,
                                       caption: 'Graded Gross Weight',
                                       invisible: !@rules[:rebin_rule],
                                       with_value: @form_object.changes.to_h['gross_weight'] }
      fields[:graded_nett_weight] = { renderer: :label,
                                      caption: 'Graded Nett Weight',
                                      invisible: !@rules[:rebin_rule],
                                      with_value: @form_object.changes.to_h['nett_weight'] }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      grower_grading_rule_id = @options[:grower_grading_rule_id].nil_or_empty? ? @repo.find_grower_grading_rule_item(@options[:id]).grower_grading_rule_id : @options[:grower_grading_rule_id]
      grading_rule = @repo.find_grower_grading_rule(grower_grading_rule_id)
      cultivar_group_id = @form_object.cultivar_group_id.nil_or_empty? ? grading_rule[:cultivar_group_id] : @form_object.cultivar_group_id
      cultivar_id = @form_object.cultivar_id.nil_or_empty? ? grading_rule[:cultivar_id] : @form_object.cultivar_id

      fields = {
        id: { renderer: :hidden,
              value: @options[:id] },
        created_by: { renderer: :hidden },
        updated_by: { renderer: :hidden },
        grading_rule: { renderer: :label,
                        caption: 'Grading Rule',
                        readonly: true },
        grower_grading_rule_id: { renderer: :hidden,
                                  value: grower_grading_rule_id },
        commodity_id: { renderer: :select,
                        options: @repo.for_select_grading_rule_commodities(
                          cultivar_group_id, cultivar_id
                        ),
                        disabled_options: MasterfilesApp::CommodityRepo.new.for_select_inactive_commodities,
                        prompt: true,
                        required: true,
                        caption: 'Commodity' },
        marketing_variety_id: { renderer: :select,
                                options: @repo.for_select_cultivar_group_marketing_varieties(
                                  cultivar_group_id, cultivar_id
                                ),
                                disabled_options: MasterfilesApp::CultivarRepo.new.for_select_inactive_marketing_varieties,
                                caption: 'Marketing Variety',
                                required: true,
                                prompt: 'Select Marketing Variety',
                                searchable: true,
                                remove_search_for_small_list: false },
        std_fruit_size_count_id: { renderer: :select,
                                   options: @fruit_size_repo.for_select_std_fruit_size_counts(
                                     where: { commodity_id: @form_object.commodity_id }
                                   ),
                                   disabled_options: @fruit_size_repo.for_select_inactive_std_fruit_size_counts,
                                   caption: 'Std Size Count',
                                   hide_on_load: @rules[:rebin_rule],
                                   prompt: 'Select Size Count',
                                   searchable: true,
                                   remove_search_for_small_list: false },
        fruit_actual_counts_for_pack_id: { renderer: :select,
                                           options: @fruit_size_repo.for_select_fruit_actual_counts_for_packs(
                                             where: { std_fruit_size_count_id: @form_object.std_fruit_size_count_id }
                                           ),
                                           disabled_options: @fruit_size_repo.for_select_inactive_fruit_actual_counts_for_packs,
                                           caption: 'Actual Count',
                                           hide_on_load: @rules[:rebin_rule],
                                           prompt: 'Select Actual Count',
                                           searchable: true,
                                           remove_search_for_small_list: false },
        fruit_size_reference_id: { renderer: :select,
                                   options: @fruit_size_repo.for_select_fruit_size_references,
                                   disabled_options: @fruit_size_repo.for_select_inactive_fruit_size_references,
                                   caption: 'Size Reference',
                                   hide_on_load: @rules[:rebin_rule],
                                   prompt: 'Select Size Reference',
                                   searchable: true,
                                   remove_search_for_small_list: false },
        grade_id: { renderer: :select,
                    options: @fruit_repo.for_select_grades,
                    disabled_options: @fruit_repo.for_select_inactive_grades,
                    caption: 'Grade',
                    hide_on_load: @rules[:rebin_rule],
                    required: true,
                    prompt: 'Select Grade',
                    searchable: true,
                    remove_search_for_small_list: false },
        rmt_class_id: { renderer: :select,
                        options: @fruit_repo.for_select_rmt_classes,
                        disabled_options: @fruit_repo.for_select_inactive_rmt_classes,
                        caption: 'Rmt Class',
                        prompt: 'Select Rmt Class',
                        searchable: true,
                        remove_search_for_small_list: false },
        rmt_size_id: { renderer: :select,
                       options: MasterfilesApp::RmtSizeRepo.new.for_select_rmt_sizes,
                       caption: 'Rmt Size',
                       hide_on_load: !@rules[:rebin_rule],
                       prompt: 'Select Rmt Class',
                       searchable: true,
                       remove_search_for_small_list: false },
        inspection_type_id: { renderer: :select,
                              options: MasterfilesApp::QualityRepo.new.for_select_inspection_types,
                              disabled_options: MasterfilesApp::QualityRepo.new.for_select_inactive_inspection_types,
                              caption: 'Inspection Type',
                              prompt: 'Select Inspection Type',
                              searchable: true,
                              remove_search_for_small_list: false  },
        created_at: { renderer: :label,
                      format: :without_timezone_or_seconds },
        updated_at: { renderer: :label,
                      format: :without_timezone_or_seconds }
      }

      if @rules[:show_legacy_data_fields]
        @rules[:legacy_data_fields].each do |v|
          fields[v.to_sym] = {}
        end
      end

      return fields unless @rules[:show_rule_item_changes_fields]

      fields[:graded_rmt_class_id] = { renderer: :select,
                                       options: @fruit_repo.for_select_rmt_classes,
                                       caption: 'Graded Rmt Class',
                                       prompt: 'Select Graded Rmt Class',
                                       searchable: true,
                                       remove_search_for_small_list: false }
      fields[:graded_rmt_size_id] = { renderer: :select,
                                      options: MasterfilesApp::RmtSizeRepo.new.for_select_rmt_sizes,
                                      caption: 'Graded Rmt Size',
                                      hide_on_load: !@rules[:rebin_rule],
                                      prompt: 'Select Graded Rmt Size',
                                      searchable: true,
                                      remove_search_for_small_list: false }
      fields[:graded_grade_id] = { renderer: :select,
                                   options: @fruit_repo.for_select_grades,
                                   caption: 'Graded Grade',
                                   hide_on_load: @rules[:rebin_rule],
                                   prompt: 'Select Graded Grade',
                                   searchable: true,
                                   remove_search_for_small_list: false }
      fields[:graded_std_fruit_size_count_id] = { renderer: :select,
                                                  options: @fruit_size_repo.for_select_std_fruit_size_counts(
                                                    where: { commodity_id: @form_object.commodity_id }
                                                  ),
                                                  caption: 'Graded Size Count',
                                                  hide_on_load: @rules[:rebin_rule],
                                                  prompt: 'Select Graded Size Count',
                                                  searchable: true,
                                                  remove_search_for_small_list: false }
      fields[:graded_gross_weight] = { renderer: :numeric,
                                       hide_on_load: !@rules[:rebin_rule],
                                       caption: 'Graded Gross Weight' }
      fields[:graded_nett_weight] = { renderer: :numeric,
                                      hide_on_load: !@rules[:rebin_rule],
                                      caption: 'Graded Nett Weight' }
      fields
    end

    def make_form_object # rubocop:disable Metrics/AbcSize
      if @mode == :new
        make_new_form_object
        return
      end

      hash = @repo.find_grower_grading_rule_item(@options[:id])
      legacy_data = AppConst::CR_PROD.grower_grading_json_fields[:legacy_data].map { |f| [f, hash.legacy_data.to_h[f.to_s]] }
      changes = @repo.grower_grading_rule_changes(hash[:grower_grading_rule_id]).map { |f| ["graded_#{f}".to_sym, hash.changes.to_h[f.to_s]] }
      @form_object = OpenStruct.new(hash.to_h.merge(Hash[legacy_data], Hash[changes]))
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(ProductionApp::GrowerGradingRuleItem,
                                                 merge_hash: {
                                                   grower_grading_rule_id: @options[:grower_grading_rule_id],
                                                   grading_rule: @repo.get(:grower_grading_rules, @options[:grower_grading_rule_id], :rule_name)
                                                 })
    end

    def handle_behaviour
      case @mode
      when :commodity
        commodity_change
      when :std_fruit_size_count
        std_fruit_size_count_change
      when :grade
        grade_change
      when :rmt_class
        rmt_class_change
      when :rmt_size
        rmt_size_change
      else
        unhandled_behaviour!
      end
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :commodity_id,
                                  notify: [{ url: "/production/grower_grading/grower_grading_rules/#{@form_object.grower_grading_rule_id}/grower_grading_rule_items/ui_change/commodity" }]
        behaviour.dropdown_change :std_fruit_size_count_id,
                                  notify: [{ url: "/production/grower_grading/grower_grading_rules/#{@form_object.grower_grading_rule_id}/grower_grading_rule_items/ui_change/std_fruit_size_count",
                                             param_keys: %i[grower_grading_rule_item_commodity_id] }]
        behaviour.dropdown_change :grade_id,
                                  notify: [{ url: "/production/grower_grading/grower_grading_rules/#{@form_object.grower_grading_rule_id}/grower_grading_rule_items/ui_change/grade" }]
        behaviour.dropdown_change :rmt_class_id,
                                  notify: [{ url: "/production/grower_grading/grower_grading_rules/#{@form_object.grower_grading_rule_id}/grower_grading_rule_items/ui_change/rmt_class" }]
        behaviour.dropdown_change :rmt_size_id,
                                  notify: [{ url: "/production/grower_grading/grower_grading_rules/#{@form_object.grower_grading_rule_id}/grower_grading_rule_items/ui_change/rmt_size" }]
      end
    end

    def commodity_change
      size_counts = if params[:changed_value].blank?
                      []
                    else
                      MasterfilesApp::FruitSizeRepo.new.for_select_std_fruit_size_counts(
                        where: { commodity_id: params[:changed_value] }
                      )
                    end
      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'grower_grading_rule_item_std_fruit_size_count_id',
                                   options_array: size_counts),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'grower_grading_rule_item_fruit_actual_counts_for_pack_id',
                                   options_array: [])])
    end

    def std_fruit_size_count_change # rubocop:disable Metrics/AbcSize
      fruit_size_repo = MasterfilesApp::FruitSizeRepo.new
      commodity_id = params[:grower_grading_rule_item_commodity_id]
      if params[:changed_value].blank? || commodity_id.blank?
        actual_counts = []
        size_counts = []
      else
        actual_counts = fruit_size_repo.for_select_fruit_actual_counts_for_packs(
          where: { std_fruit_size_count_id: params[:changed_value] }
        )
        size_counts = fruit_size_repo.for_select_std_fruit_size_counts(
          where: { commodity_id: commodity_id },
          exclude: { id: params[:changed_value] }
        )
      end
      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'grower_grading_rule_item_fruit_actual_counts_for_pack_id',
                                   options_array: actual_counts),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'grower_grading_rule_item_graded_std_fruit_size_count_id',
                                   options_array: size_counts)])
    end

    def grade_change
      grades = if params[:changed_value].blank?
                 []
               else
                 MasterfilesApp::FruitRepo.new.for_select_grades(
                   exclude: { id: params[:changed_value] }
                 )
               end
      json_replace_select_options('grower_grading_rule_item_graded_grade_id', grades)
    end

    def rmt_class_change
      rmt_classes = if params[:changed_value].blank?
                      []
                    else
                      MasterfilesApp::FruitRepo.new.for_select_rmt_classes(
                        exclude: { id: params[:changed_value] }
                      )
                    end
      json_replace_select_options('grower_grading_rule_item_graded_rmt_class_id', rmt_classes)
    end

    def rmt_size_change
      rmt_sizes = if params[:changed_value].blank?
                    []
                  else
                    MasterfilesApp::RmtSizeRepo.new.for_select_rmt_sizes(
                      exclude: { id: params[:changed_value] }
                    )
                  end
      json_replace_select_options('grower_grading_rule_item_graded_rmt_size_id', rmt_sizes)
    end
  end
end
