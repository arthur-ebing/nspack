# frozen_string_literal: true

module UiRules
  class GrowerGradingRebinRule < Base
    def generate_rules
      @repo = ProductionApp::GrowerGradingRepo.new
      make_form_object

      @rules[:changes_made_fields] = AppConst::CR_PROD.grower_grading_json_fields[:rebin_changes]
      @rules[:show_changes_fields] = !@rules[:changes_made_fields].empty?

      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'grower_grading_rebin'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      grower_grading_pool_id_label = @repo.get(:grower_grading_pools, @form_object.grower_grading_pool_id, :pool_name)
      grower_grading_rule_item_id_label = @repo.find_grower_grading_rule_item(@form_object.grower_grading_rule_item_id)&.rule_item_code
      rmt_class_id_label = @repo.get(:rmt_classes, @form_object.rmt_class_id, :rmt_class_code)
      rmt_size_id_label = @repo.get(:rmt_sizes, @form_object.rmt_size_id, :size_code)
      fields[:grower_grading_pool_id] = { renderer: :label,
                                          with_value: grower_grading_pool_id_label,
                                          caption: 'Grower Grading Pool' }
      fields[:grower_grading_rule_item_id] = { renderer: :hidden,
                                               with_value: grower_grading_rule_item_id_label,
                                               caption: 'Grower Grading Rule Item' }
      fields[:rmt_class_id] = { renderer: :label,
                                with_value: rmt_class_id_label,
                                caption: 'Rmt Class' }
      fields[:rmt_size_id] = { renderer: :label,
                               with_value: rmt_size_id_label,
                               caption: 'Rmt Size' }
      fields[:changes_made] = { renderer: :label }
      fields[:rebins_quantity] = { renderer: :label }
      fields[:gross_weight] = { renderer: :label }
      fields[:nett_weight] = { renderer: :label }
      fields[:pallet_rebin] = { renderer: :label,
                                as_boolean: true }
      fields[:completed] = { renderer: :label,
                             as_boolean: true }
      fields[:active] = { renderer: :label,
                          as_boolean: true }
      fields[:created_by] = { renderer: :label }
      fields[:updated_by] = { renderer: :label }

      return fields unless @rules[:show_changes_fields]

      graded_rmt_class_id_label = @form_object.changes_made.to_h['rmt_class_id'].nil_or_empty? ? '' : @repo.get(:rmt_classes, @form_object.changes_made.to_h['rmt_class_id'], :rmt_class_code)
      graded_rmt_size_id_label = @form_object.changes_made.to_h['rmt_size_id'].nil_or_empty? ? '' : @repo.get(:rmt_sizes, @form_object.changes_made.to_h['rmt_size_id'], :size_code)
      fields[:graded_rmt_class_id] = { renderer: :label,
                                       caption: 'Graded Rmt Class',
                                       with_value: graded_rmt_class_id_label }
      fields[:graded_rmt_size_id] = { renderer: :label,
                                      caption: 'Graded Rmt Size',
                                      with_value: graded_rmt_size_id_label }
      fields[:graded_gross_weight] = { renderer: :label,
                                       caption: 'Graded Gross Weight',
                                       with_value: @form_object.changes_made.to_h['gross_weight'] }
      fields[:graded_nett_weight] = { renderer: :label,
                                      caption: 'Graded Nett Weight',
                                      with_value: @form_object.changes_made.to_h['nett_weight'] }
    end

    def common_fields
      {
        grower_grading_pool_id: {},
        grower_grading_rule_item_id: {},
        rmt_class_id: {},
        rmt_size_id: {},
        changes_made: {},
        rebins_quantity: {},
        gross_weight: {},
        nett_weight: {},
        pallet_rebin: { renderer: :checkbox },
        completed: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      hash = @repo.find_grower_grading_rebin(@options[:id])
      changes_made = AppConst::CR_PROD.grower_grading_json_fields[:rebin_changes].map { |f| ["graded_#{f}".to_sym, hash.changes_made.to_h[f.to_s]] }
      @form_object = OpenStruct.new(hash.to_h.merge(Hash[changes_made]))
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(ProductionApp::GrowerGradingRebin)
    end
  end
end
