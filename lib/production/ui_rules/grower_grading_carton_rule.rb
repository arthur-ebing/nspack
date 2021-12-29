# frozen_string_literal: true

module UiRules
  class GrowerGradingCartonRule < Base
    def generate_rules
      @repo = ProductionApp::GrowerGradingRepo.new
      @party_repo = MasterfilesApp::PartyRepo.new

      make_form_object

      @rules[:changes_made_fields] = AppConst::CR_PROD.grower_grading_json_fields[:carton_changes]
      @rules[:show_changes_fields] = !@rules[:changes_made_fields].empty?

      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'grower_grading_carton'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      grower_grading_pool_id_label = @repo.get(:grower_grading_pools, @form_object.grower_grading_pool_id, :pool_name)
      grower_grading_rule_item_id_label = @repo.find_grower_grading_rule_item(@form_object.grower_grading_rule_item_id)&.rule_item_code
      product_resource_allocation_id_label = @repo.get(:product_resource_allocations, @form_object.product_resource_allocation_id, :id)
      pm_bom_id_label = @repo.get(:pm_boms, @form_object.pm_bom_id, :bom_code)
      std_fruit_size_count_id_label = @repo.get(:std_fruit_size_counts, @form_object.std_fruit_size_count_id, :size_count_value)
      fruit_actual_counts_for_pack_id_label = @repo.get(:fruit_actual_counts_for_packs, @form_object.fruit_actual_counts_for_pack_id, :actual_count_for_pack)
      marketing_org_party_role_id_label = @party_repo.find_party_role(@form_object.marketing_org_party_role_id)&.party_name
      packed_tm_group_id_label = @repo.get(:target_market_groups, @form_object.packed_tm_group_id, :target_market_group_name)
      target_market_id_label = @repo.get(:target_markets, @form_object.target_market_id, :target_market_name)
      inventory_code_id_label = @repo.get(:inventory_codes, @form_object.inventory_code_id, :inventory_code)
      rmt_class_id_label = @repo.get(:rmt_classes, @form_object.rmt_class_id, :rmt_class_code)
      grade_id_label = @repo.get(:grades, @form_object.grade_id, :grade_code)
      marketing_variety_id_label = @repo.get(:marketing_varieties, @form_object.marketing_variety_id, :marketing_variety_code)
      fruit_size_reference_id_label = @repo.get(:fruit_size_references, @form_object.fruit_size_reference_id, :size_reference)

      fields[:grower_grading_pool_id] = { renderer: :label,
                                          with_value: grower_grading_pool_id_label,
                                          caption: 'Grading Pool' }
      fields[:grower_grading_rule_item_id] = { renderer: :label,
                                               with_value: grower_grading_rule_item_id_label,
                                               caption: 'Grading Rule Item' }
      fields[:product_resource_allocation_id] = { renderer: :label,
                                                  with_value: product_resource_allocation_id_label,
                                                  caption: 'Product Resource Allocation' }
      fields[:pm_bom_id] = { renderer: :label,
                             with_value: pm_bom_id_label,
                             caption: 'Pm Bom' }
      fields[:std_fruit_size_count_id] = { renderer: :label,
                                           with_value: std_fruit_size_count_id_label,
                                           caption: 'Size Count' }
      fields[:fruit_actual_counts_for_pack_id] = { renderer: :label,
                                                   with_value: fruit_actual_counts_for_pack_id_label,
                                                   caption: 'Actual Count' }
      fields[:marketing_org_party_role_id] = { renderer: :label,
                                               with_value: marketing_org_party_role_id_label,
                                               caption: 'Marketing Org' }
      fields[:packed_tm_group_id] = { renderer: :label,
                                      with_value: packed_tm_group_id_label,
                                      caption: 'Packed Tm Group' }
      fields[:target_market_id] = { renderer: :label,
                                    with_value: target_market_id_label,
                                    caption: 'Target Market' }
      fields[:inventory_code_id] = { renderer: :label,
                                     with_value: inventory_code_id_label,
                                     caption: 'Inventory Code' }
      fields[:rmt_class_id] = { renderer: :label,
                                with_value: rmt_class_id_label,
                                caption: 'Rmt Class' }
      fields[:grade_id] = { renderer: :label,
                            with_value: grade_id_label,
                            caption: 'Grade' }
      fields[:marketing_variety_id] = { renderer: :label,
                                        with_value: marketing_variety_id_label,
                                        caption: 'Marketing Variety' }
      fields[:fruit_size_reference_id] = { renderer: :label,
                                           with_value: fruit_size_reference_id_label,
                                           caption: 'Fruit Size Reference' }
      fields[:changes_made] = { renderer: :label }
      fields[:carton_quantity] = { renderer: :label }
      fields[:inspected_quantity] = { renderer: :label }
      fields[:not_inspected_quantity] = { renderer: :label }
      fields[:failed_quantity] = { renderer: :label }
      fields[:gross_weight] = { renderer: :label }
      fields[:nett_weight] = { renderer: :label }
      fields[:completed] = { renderer: :label,
                             as_boolean: true }
      fields[:active] = { renderer: :label,
                          as_boolean: true }
      fields[:created_by] = { renderer: :label }
      fields[:updated_by] = { renderer: :label }

      return fields unless @rules[:show_changes_fields]

      graded_rmt_class_id_label = @form_object.changes_made.to_h['rmt_class_id'].nil_or_empty? ? '' : @repo.get(:rmt_classes, @form_object.changes_made.to_h['rmt_class_id'], :rmt_class_code)
      graded_grade_id_label = @form_object.changes_made.to_h['grade_id'].nil_or_empty? ? '' : @repo.get(:grades, @form_object.changes_made.to_h['grade_id'], :grade_code)
      graded_size_count_id_label = @form_object.changes_made.to_h['std_fruit_size_count_id'].nil_or_empty? ? '' : @repo.get(:std_fruit_size_counts, @form_object.changes_made.to_h['std_fruit_size_count_id'], :size_count_value)
      fields[:graded_rmt_class_id] = { renderer: :label,
                                       caption: 'Graded Rmt Class',
                                       with_value: graded_rmt_class_id_label }
      fields[:graded_grade_id] = { renderer: :label,
                                   caption: 'Graded Grade',
                                   with_value: graded_grade_id_label }
      fields[:graded_std_fruit_size_count_id] = { renderer: :label,
                                                  caption: 'Graded Size Count',
                                                  with_value: graded_size_count_id_label }
    end

    def common_fields
      {
        pool_name: { renderer: :label,
                     caption: 'Pool Name',
                     readonly: true },
        grower_grading_pool_id: { renderer: :hidden },
        grower_grading_rule_item_id: { renderer: :hidden },
        product_resource_allocation_id: { renderer: :hidden },
        pm_bom_id: { renderer: :hidden },
        std_fruit_size_count_id: { renderer: :hidden },
        fruit_actual_counts_for_pack_id: { renderer: :hidden },
        marketing_org_party_role_id: { renderer: :hidden },
        packed_tm_group_id: { renderer: :hidden },
        target_market_id: { renderer: :hidden },
        inventory_code_id: { renderer: :hidden },
        rmt_class_id: { renderer: :hidden },
        grade_id: { renderer: :hidden },
        marketing_variety_id: { renderer: :hidden },
        fruit_size_reference_id: { renderer: :hidden },
        changes_made: {},
        carton_quantity: {},
        inspected_quantity: {},
        not_inspected_quantity: {},
        failed_quantity: {},
        gross_weight: { renderer: :numeric },
        nett_weight: { renderer: :numeric },
        completed: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      hash = @repo.find_grower_grading_carton(@options[:id])
      changes_made = AppConst::CR_PROD.grower_grading_json_fields[:carton_changes].map { |f| ["graded_#{f}".to_sym, hash.changes_made.to_h[f.to_s]] }
      @form_object = OpenStruct.new(hash.to_h.merge(Hash[changes_made]))
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(ProductionApp::GrowerGradingCarton)
    end
  end
end
