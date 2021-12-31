# frozen_string_literal: true

module ProductionApp
  class ApplyGrowerGradingRule < BaseService
    attr_reader :repo, :rule_id, :user_name, :rebin_rule, :rule_item, :grading_pool_ids, :object_ids, :changes

    def initialize(id, user_name)
      @repo = ProductionApp::GrowerGradingRepo.new
      @rule_id = id
      @user_name = user_name
      @changes = repo.grower_grading_rule_changes(rule_id)
    end

    def call
      res = apply_grower_grading_rule
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      success_response('ok', rule_id: rule_id)
    end

    private

    def apply_grower_grading_rule # rubocop:disable Metrics/AbcSize
      return failed_response("Rule #{rule_id} does not exist") unless repo.rule_exists?(rule_id)

      @rebin_rule = repo.get(:grower_grading_rules, :rebin_rule, rule_id)
      rule_item_ids = repo.select_values(:grower_grading_rule_items, :id, grower_grading_rule_id: rule_id, active: true)
      return failed_response('There are no active rule items to apply') if rule_item_ids.nil_or_empty?

      res = apply_rule_item_changes(rule_item_ids)
      return res unless res.success

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def apply_rule_item_changes(rule_item_ids) # rubocop:disable Metrics/AbcSize
      table_name = rebin_rule ? 'grower_grading_rebins' : 'grower_grading_cartons'
      rule_item_ids.each do |rule_item_id|
        @rule_item = repo.find_grower_grading_rule_item(rule_item_id)

        res = resolve_rule_item_pools
        return res unless res.success

        res = resolve_rule_item_objects(table_name)
        return res unless res.success

        repo.update(:grower_grading_pools, grading_pool_ids, pool_update_params)
        repo.update(table_name.to_sym, object_ids, object_update_params)
      end
      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def resolve_rule_item_pools
      match_pools_on = repo.match_pools_on_rule_item_attrs(rule_item.id)
      @grading_pool_ids = repo.find_pools_matching_rule_item_on(match_pools_on)
      return failed_response('There are no grading pools to update') if grading_pool_ids.nil_or_empty?

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def resolve_rule_item_objects(table_name)
      match_objects_on = match_rule_item_objects_on
      @object_ids = repo.select_values(table_name.to_sym, :id, match_objects_on)
      return failed_response("There are no #{table_name} to update") if object_ids.nil_or_empty?

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def match_rule_item_objects_on
      match_on = {
        grower_grading_pool_id: grading_pool_ids
      }
      changes.each { |column| match_on[column.to_sym] = rule_item[column.to_sym] }
      match_on[:marketing_variety_id] = rule_item.marketing_variety_id unless rebin_rule
      match_on
    end

    def object_update_params
      changes_made = rule_item.changes.nil? ? { 'descriptions' => {} } : Hash[rule_item.changes]
      changes_made['descriptions'] = resolve_changes_made_descriptions
      {
        grower_grading_rule_item_id: rule_item.id,
        updated_by: user_name,
        completed: true,
        changes_made: repo.hash_for_jsonb_col(changes_made)
      }
    end

    def resolve_changes_made_descriptions
      desc = {}
      changes.each { |column| resolve_change_description(desc, column) }
      desc
    end

    def resolve_change_description(desc, column) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      case column.to_s
      when 'std_fruit_size_count_id'
        desc['graded_size_count'] = rule_item.changes['std_fruit_size_count_id'].nil_or_empty? ? '' : repo.get(:std_fruit_size_counts, :size_count_value, rule_item.changes['std_fruit_size_count_id'])
      when 'grade_id'
        desc['graded_grade_code'] = rule_item.changes['grade_id'].nil_or_empty? ? '' : repo.get(:grades, :grade_code, rule_item.changes['grade_id'])
      when 'rmt_class_id'
        desc['graded_rmt_class_code'] = rule_item.changes['rmt_class_id'].nil_or_empty? ? '' : repo.get(:rmt_classes, :rmt_class_code, rule_item.changes['rmt_class_id'])
      when 'rmt_size_id'
        desc['graded_rmt_size_code'] = rule_item.changes['rmt_size_id'].nil_or_empty? ? '' : repo.get(:rmt_sizes, :size_code, rule_item.changes['rmt_size_id'])
      when 'gross_weight'
        desc['graded_gross_weight'] =  rule_item.changes['gross_weight']
      when 'nett_weight'
        desc['graded_nett_weight'] =  rule_item.changes['nett_weight']
      end
      desc
    end

    def pool_update_params
      {
        grower_grading_rule_id: rule_id,
        completed: true,
        rule_applied: true,
        rule_applied_by: user_name,
        rule_applied_at: Time.now
      }
    end
  end
end
