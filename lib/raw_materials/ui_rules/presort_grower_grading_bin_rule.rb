# frozen_string_literal: true

module UiRules
  class PresortGrowerGradingBinRule < Base
    def generate_rules
      @repo = RawMaterialsApp::PresortGrowerGradingRepo.new
      @fruit_repo = MasterfilesApp::FruitRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'presort_grower_grading_bin'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      presort_grower_grading_pool_id_label = @repo.get(:presort_grower_grading_pools, @form_object.presort_grower_grading_pool_id, :maf_lot_number)
      farm_id_label = @repo.get(:farms, @form_object.farm_id, :farm_code)
      rmt_class_id_label = @repo.get(:rmt_classes, @form_object.rmt_class_id, :rmt_class_code)
      rmt_size_id_label = @repo.get(:rmt_sizes, @form_object.rmt_size_id, :size_code)
      treatment_id_label = @repo.get(:treatments, @form_object.treatment_id, :treatment_code)
      fields[:presort_grower_grading_pool_id] = { renderer: :label,
                                                  with_value: presort_grower_grading_pool_id_label,
                                                  caption: 'Maf Lot Number' }
      fields[:farm_id] = { renderer: :label,
                           with_value: farm_id_label,
                           caption: 'Farm' }
      fields[:rmt_class_id] = { renderer: :label,
                                with_value: rmt_class_id_label,
                                caption: 'Rmt Class' }
      fields[:rmt_size_id] = { renderer: :label,
                               with_value: rmt_size_id_label,
                               caption: 'Rmt Size' }
      fields[:maf_rmt_code] = { renderer: :label }
      fields[:maf_article] = { renderer: :label }
      fields[:maf_class] = { renderer: :label }
      fields[:maf_colour] = { renderer: :label }
      fields[:maf_count] = { renderer: :label }
      fields[:maf_article_count] = { renderer: :label }
      fields[:maf_weight] = { renderer: :label }
      fields[:maf_tipped_quantity] = { renderer: :label }
      fields[:maf_total_lot_weight] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:created_by] = { renderer: :label }
      fields[:updated_by] = { renderer: :label }
      fields[:created_at] = { renderer: :label,
                              format: :without_timezone_or_seconds }
      fields[:updated_at] = { renderer: :label,
                              format: :without_timezone_or_seconds }
      fields[:graded] = { renderer: :label, as_boolean: true }
      fields[:treatment_id] = { renderer: :label,
                                with_value: treatment_id_label,
                                caption: 'Colour' }
      fields[:rmt_bin_weight] = { renderer: :label }
      fields[:adjusted_weight] = { renderer: :label }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      presort_grower_grading_pool_id = @options[:presort_grading_pool_id].nil_or_empty? ? @repo.find_presort_grower_grading_bin(@options[:id]).presort_grower_grading_pool_id : @options[:presort_grading_pool_id]
      if @mode == :new
        farm_renderer = { renderer: :select,
                          options: MasterfilesApp::FarmRepo.new.for_select_farms(where: { id: @form_object.farm_id }),
                          disabled_options: MasterfilesApp::FarmRepo.new.for_select_inactive_farms,
                          caption: 'Farm' }
        rmt_class_renderer = { renderer: :select,
                               options: @fruit_repo.for_select_rmt_classes,
                               disabled_options: @fruit_repo.for_select_inactive_rmt_classes,
                               caption: 'Rmt Class',
                               prompt: 'Select Rmt Class',
                               searchable: true,
                               remove_search_for_small_list: false }
        rmt_size_renderer = { renderer: :select,
                              options: MasterfilesApp::RmtSizeRepo.new.for_select_rmt_sizes,
                              caption: 'Rmt Size',
                              prompt: 'Select Rmt Class',
                              searchable: true,
                              remove_search_for_small_list: false }
        colour_renderer = { renderer: :select,
                            options: @fruit_repo.for_select_treatments,
                            disabled_options: @fruit_repo.for_select_inactive_treatments,
                            caption: 'Colour',
                            prompt: 'Select Colour',
                            searchable: true,
                            remove_search_for_small_list: false }
      else
        farm_renderer = { renderer: :label,
                          with_value: @repo.get(:farms, @form_object.farm_id, :farm_code),
                          caption: 'Farm' }
        rmt_class_renderer = { renderer: :label,
                               with_value: @repo.get(:rmt_classes, @form_object.rmt_class_id, :rmt_class_code),
                               caption: 'Rmt Class' }
        rmt_size_renderer = { renderer: :label,
                              with_value: @repo.get(:rmt_sizes, @form_object.rmt_size_id, :size_code),
                              caption: 'Rmt Size' }
        colour_renderer = { renderer: :label,
                            with_value: @repo.get(:treatments, @form_object.treatment_id, :treatment_code),
                            caption: 'Colour' }
      end
      {
        maf_lot_number: { renderer: :label,
                          caption: 'Maf Lot Number',
                          readonly: true },
        presort_grower_grading_pool_id: { renderer: :hidden,
                                          value: presort_grower_grading_pool_id },
        farm_id: farm_renderer,
        rmt_class_id: rmt_class_renderer,
        rmt_size_id: rmt_size_renderer,
        treatment_id: colour_renderer,
        maf_rmt_code: {},
        maf_article: {},
        maf_class: {},
        maf_colour: {},
        maf_count: {},
        maf_article_count: {},
        maf_weight: { renderer: :numeric },
        maf_tipped_quantity: {},
        maf_total_lot_weight: {},
        created_by: {},
        updated_by: {},
        graded: { renderer: :checkbox },
        rmt_bin_weight: { renderer: :numeric }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_presort_grower_grading_bin(@options[:id])
    end

    def make_new_form_object
      presort_pool = @repo.find_presort_grower_grading_pool(@options[:presort_grading_pool_id])
      @form_object = new_form_object_from_struct(RawMaterialsApp::PresortGrowerGradingBin,
                                                 merge_hash: {
                                                   presort_grower_grading_pool_id: @options[:presort_grading_pool_id],
                                                   maf_lot_number: presort_pool[:maf_lot_number],
                                                   farm_id: presort_pool[:farm_id],
                                                   maf_weight: 0,
                                                   rmt_bin_weight: 0
                                                 })
    end
  end
end
