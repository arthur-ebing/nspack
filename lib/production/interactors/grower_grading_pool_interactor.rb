# frozen_string_literal: true

module ProductionApp
  class GrowerGradingPoolInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_grower_grading_pool(params) # rubocop:disable Metrics/AbcSize
      res = validate_new_grower_grading_pool_params(params)
      return validation_failed_response(res) if res.failure?

      pool_res = nil
      repo.transaction do
        pool_res = CreateGrowerGradingPool.call(res[:production_run_id], @user.user_name, res.to_h)
        raise Crossbeams::InfoError, pool_res.message unless pool_res.success

        log_transaction
      end

      instance = grower_grading_pool(pool_res.instance[:grading_pool_id])
      success_response("Created grower grading pool #{instance.pool_name}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { pool_name: ['This grower grading pool already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_grower_grading_pool(id, params)
      res = validate_edit_grower_grading_pool_params(include_updated_by_in_changeset(params))
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_grower_grading_pool(id, res)
        log_transaction
      end
      instance = grower_grading_pool(id)
      success_response("Updated grower grading pool #{instance.pool_name}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_grower_grading_pool(id) # rubocop:disable Metrics/AbcSize
      name = grower_grading_pool(id).pool_name
      repo.transaction do
        repo.delete_grower_grading_pool(id)
        log_status(:grower_grading_pools, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted grower grading pool #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete grower grading pool. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::GrowerGradingPool.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def create_grading_pools(production_run_ids) # rubocop:disable Metrics/AbcSize
      return failed_response('Production Runs selection cannot be empty') if production_run_ids.nil_or_empty?

      repo.transaction do
        production_run_ids.each do |production_run_id|
          next if production_run_id.nil_or_empty?

          res = CreateGrowerGradingPool.call(production_run_id, @user.user_name)
          raise Crossbeams::InfoError, res.message unless res.success
        end
        log_transaction
      end

      success_response('Created grading pools')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def mark_pool_as_complete(id)
      complete_a_record(:grower_grading_pools, id, status_text: 'COMPLETED')
    end

    def mark_pool_as_incomplete(id)
      reject_a_record(:grower_grading_pools, id, status_text: 'UN-COMPLETED')
    end

    def complete_objects_grading(id, object_name)
      table_name = "grower_grading_#{object_name}"
      object_ids = repo.select_values(table_name.to_sym, :id, grower_grading_pool_id: id)

      repo.transaction do
        repo.update(table_name.to_sym, object_ids, completed: true)
        log_multiple_statuses(table_name.to_sym, object_ids, 'COMPLETED')
        log_transaction
      end
      success_response("#{table_name} completed successfully")
    end

    def reopen_objects_grading(id, object_name)
      table_name = "grower_grading_#{object_name}"
      object_ids = repo.select_values(table_name.to_sym, :id, grower_grading_pool_id: id)

      repo.transaction do
        repo.update(table_name.to_sym, object_ids, completed: false)
        log_multiple_statuses(table_name.to_sym, object_ids, 'RE-OPENED')
        log_transaction
      end
      success_response("#{table_name} reopened successfully")
    end

    private

    def repo
      @repo ||= GrowerGradingRepo.new
    end

    def grower_grading_pool(id)
      repo.find_grower_grading_pool(id)
    end

    def validate_new_grower_grading_pool_params(params)
      NewGrowerGradingPoolSchema.call(params)
    end

    def validate_edit_grower_grading_pool_params(params)
      EditGrowerGradingPoolSchema.call(params)
    end
  end
end
