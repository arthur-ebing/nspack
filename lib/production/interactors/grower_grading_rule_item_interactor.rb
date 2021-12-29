# frozen_string_literal: true

module ProductionApp
  class GrowerGradingRuleItemInteractor < BaseInteractor
    def create_grower_grading_rule_item(params) # rubocop:disable Metrics/AbcSize
      legacy_data = AppConst::CR_PROD.grower_grading_json_fields[:legacy_data].map { |f| [f, params[f]] }
      params[:legacy_data] = Hash[legacy_data] unless legacy_data.empty?
      changes = repo.grower_grading_rule_changes(params[:grower_grading_rule_id]).map { |f| [f, params["graded_#{f}".to_sym]] }
      params[:changes] = Hash[changes] unless changes.empty?

      res = validate_grower_grading_rule_item_params(include_created_by_in_changeset(params))
      return validation_failed_response(res) if res.failure?

      id = repo.look_for_existing_rule_item_id(res)
      if id
        instance = grower_grading_rule_item(id)
        return failed_response("Found existing rule item #{instance.rule_item_code}", instance)
      end

      repo.transaction do
        id = repo.create_grower_grading_rule_item(res)
        log_status(:grower_grading_rule_items, id, 'CREATED')
        log_transaction
      end
      instance = grower_grading_rule_item(id)
      success_response("Created grower grading rule item #{instance.rule_item_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { rule_item_code: ['This grower grading rule item already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_grower_grading_rule_item(id, params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity:
      legacy_data = AppConst::CR_PROD.grower_grading_json_fields[:legacy_data].map { |f| [f, params[f]] }
      params[:legacy_data] = Hash[legacy_data] unless legacy_data.empty?
      changes = repo.grower_grading_rule_changes(params[:grower_grading_rule_id]).map { |f| [f, params["graded_#{f}".to_sym]] }
      params[:changes] = Hash[changes] unless changes.empty?

      res = validate_grower_grading_rule_item_params(include_updated_by_in_changeset(params))
      return validation_failed_response(res) if res.failure?

      existing_id = repo.look_for_existing_rule_item_id(res)
      if existing_id && repo.no_rule_item_changes?(id, res)
        instance = grower_grading_rule_item(existing_id)
        return success_response("Found existing rule item #{instance.rule_item_code}", instance)
      end

      repo.transaction do
        repo.update_grower_grading_rule_item(id, res)
        log_transaction
      end
      instance = grower_grading_rule_item(id)
      success_response("Updated grower grading rule item #{instance.rule_item_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_grower_grading_rule_item(id) # rubocop:disable Metrics/AbcSize
      name = grower_grading_rule_item(id).rule_item_code
      repo.transaction do
        repo.delete_grower_grading_rule_item(id)
        log_status(:grower_grading_rule_items, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted grower grading rule item #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete grower grading rule item. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::GrowerGradingRuleItem.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def activate_grower_grading_rule_item(id)
      repo.transaction do
        repo.activate_grower_grading_rule_item(id)
        log_status(:grower_grading_rule_items, id, 'ACTIVATED')
        log_transaction
      end
      instance = grower_grading_rule_item(id)
      success_response("Activated rule item #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def deactivate_grower_grading_rule_item(id)
      repo.transaction do
        repo.deactivate_grower_grading_rule_item(id)
        log_status(:grower_grading_rule_items, id, 'DEACTIVATED')
        log_transaction
      end
      instance = grower_grading_rule_item(id)
      success_response("De-activated rule item  #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def clone_grower_grading_rule_item(id, params) # rubocop:disable Metrics/AbcSize
      legacy_data = AppConst::CR_PROD.grower_grading_json_fields[:legacy_data].map { |f| [f, params[f]] }
      params[:legacy_data] = Hash[legacy_data] unless legacy_data.empty?
      changes = repo.grower_grading_rule_changes(params[:grower_grading_rule_id]).map { |f| [f, params["graded_#{f}".to_sym]] }
      params[:changes] = Hash[changes] unless changes.empty?

      res = validate_grower_grading_rule_item_params(include_created_by_in_changeset(params).to_h.reject { |k, _| %i[id updated_by].include?(k) })
      return validation_failed_response(res) if res.failure?

      existing_id = repo.look_for_existing_rule_item_id(res)
      if existing_id
        instance = grower_grading_rule_item(existing_id)
        return failed_response("Found existing rule item #{instance.rule_item_code}", instance)
      end

      repo.transaction do
        id = repo.create_grower_grading_rule_item(res)
        log_status(:grower_grading_rule_items, id, 'CLONED')
        log_transaction
      end
      instance = grower_grading_rule_item(id)
      success_response("Cloned grower grading rule item #{instance.rule_item_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { rule_item_code: ['This grower grading rule item already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= GrowerGradingRepo.new
    end

    def grower_grading_rule_item(id)
      repo.find_grower_grading_rule_item(id)
    end

    def validate_grower_grading_rule_item_params(params)
      GrowerGradingRuleItemSchema.call(params)
    end
  end
end
