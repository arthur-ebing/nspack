# frozen_string_literal: true

module ProductionApp
  class GrowerGradingCartonInteractor < BaseInteractor
    def create_grower_grading_carton(params)
      res = validate_grower_grading_carton_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_grower_grading_carton(res)
        log_status(:grower_grading_cartons, id, 'CREATED')
        log_transaction
      end
      instance = grower_grading_carton(id)
      success_response("Created grower grading carton #{instance.grading_carton_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { grading_carton_code: ['This grower grading carton already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_grower_grading_carton(id, params)
      res = validate_grower_grading_carton_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_grower_grading_carton(id, res)
        log_transaction
      end
      instance = grower_grading_carton(id)
      success_response("Updated grower grading carton #{instance.grading_carton_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_grower_grading_carton(id) # rubocop:disable Metrics/AbcSize
      name = grower_grading_carton(id).grading_carton_code
      repo.transaction do
        repo.delete_grower_grading_carton(id)
        log_status(:grower_grading_cartons, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted grower grading carton #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete grower grading carton. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::GrowerGradingCarton.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def inline_edit_carton_fields(grower_grading_carton_id, params) # rubocop:disable Metrics/AbcSize
      val = params[:column_value]
      changes_made = changes_made_for(grower_grading_carton_id)

      case params[:column_name]
      when 'graded_size_count'
        changes_made['descriptions'][:graded_size_count] = val
        changes_made[:std_fruit_size_count_id] = repo.grading_carton_size_count_id(grower_grading_carton_id, val)
      when 'graded_grade_code'
        changes_made['descriptions'][:graded_grade_code] = val
        changes_made[:grade_id] = repo.get_id(:grades, grade_code: val)
      when 'graded_rmt_class_code'
        changes_made['descriptions'][:graded_rmt_class_code] = val
        changes_made[:rmt_class_id] = repo.get_id(:rmt_classes, rmt_class_code: val)
      end

      repo.transaction do
        repo.update_grower_grading_carton(grower_grading_carton_id, changes_made: changes_made)
        log_transaction
      end
      success_response('Updated grower grading carton', { changes: changes_made })
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= GrowerGradingRepo.new
    end

    def grower_grading_carton(id)
      repo.find_grower_grading_carton(id)
    end

    def validate_grower_grading_carton_params(params)
      GrowerGradingCartonSchema.call(params)
    end

    def changes_made_for(grower_grading_carton_id)
      changes_made = repo.get(:grower_grading_cartons, :changes_made, grower_grading_carton_id)
      changes_made.nil? ? { 'descriptions' => {} } : Hash[changes_made]
    end
  end
end
