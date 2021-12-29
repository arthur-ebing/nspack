# frozen_string_literal: true

module ProductionApp
  class GrowerGradingRuleInteractor < BaseInteractor
    def create_grower_grading_rule(params) # rubocop:disable Metrics/AbcSize
      res = validate_grower_grading_rule_params(include_created_by_in_changeset(params))
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_grower_grading_rule(res)
        log_status(:grower_grading_rules, id, 'CREATED')
        log_transaction
      end
      instance = grower_grading_rule(id)
      success_response("Created grower grading rule #{instance.rule_name}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { rule_name: ['This grower grading rule already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_grower_grading_rule(id, params)
      res = validate_grower_grading_rule_params(include_updated_by_in_changeset(params))
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_grower_grading_rule(id, res)
        log_transaction
      end
      instance = grower_grading_rule(id)
      success_response("Updated grower grading rule #{instance.rule_name}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_grower_grading_rule(id) # rubocop:disable Metrics/AbcSize
      name = grower_grading_rule(id).rule_name
      repo.transaction do
        repo.delete_grower_grading_rule(id)
        log_status(:grower_grading_rules, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted grower grading rule #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete grower grading rule. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::GrowerGradingRule.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def clone_grower_grading_rule(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_grower_grading_rule_params(include_created_by_in_changeset(params).to_h.reject { |k, _| k == :id })
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        new_grower_grading_rule_id = repo.create_grower_grading_rule(res)
        repo.clone_grower_grading_rule_items(id, { grower_grading_rule_id: new_grower_grading_rule_id })
        log_status('grower_grading_rules', id, 'CLONED')
        log_transaction
      end
      instance = grower_grading_rule(id)
      success_response("Cloned grading rule #{instance.rule_name}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def activate_grower_grading_rule(id)
      repo.transaction do
        repo.activate_grower_grading_rule(id)
        log_status(:grower_grading_rules, id, 'ACTIVATED')
        log_transaction
      end
      instance = grower_grading_rule(id)
      success_response("Activated grading rule #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def deactivate_grower_grading_rule(id)
      repo.transaction do
        repo.deactivate_grower_grading_rule(id)
        log_status(:grower_grading_rules, id, 'DEACTIVATED')
        log_transaction
      end
      instance = grower_grading_rule(id)
      success_response("De-activated grading rule  #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def apply_rule(id)
      repo.transaction do
        res = ApplyGrowerGradingRule.call(id, @user.user_name)
        raise Crossbeams::InfoError, res.message unless res.success
      end
      instance = grower_grading_rule(id)
      success_response("Applied rule  #{instance.rule_name} successfully", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= GrowerGradingRepo.new
    end

    def grower_grading_rule(id)
      repo.find_grower_grading_rule(id)
    end

    def validate_grower_grading_rule_params(params)
      GrowerGradingRuleSchema.call(params)
    end
  end
end
