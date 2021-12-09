# frozen_string_literal: true

module ProductionApp
  class GrowerGradingRebinInteractor < BaseInteractor
    def create_grower_grading_rebin(params)
      res = validate_grower_grading_rebin_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_grower_grading_rebin(res)
        log_status(:grower_grading_rebins, id, 'CREATED')
        log_transaction
      end
      instance = grower_grading_rebin(id)
      success_response("Created grower grading rebin #{instance.updated_by}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { updated_by: ['This grower grading rebin already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_grower_grading_rebin(id, params)
      res = validate_grower_grading_rebin_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_grower_grading_rebin(id, res)
        log_transaction
      end
      instance = grower_grading_rebin(id)
      success_response("Updated grower grading rebin #{instance.updated_by}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_grower_grading_rebin(id) # rubocop:disable Metrics/AbcSize
      name = grower_grading_rebin(id).updated_by
      repo.transaction do
        repo.delete_grower_grading_rebin(id)
        log_status(:grower_grading_rebins, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted grower grading rebin #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete grower grading rebin. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::GrowerGradingRebin.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def inline_edit_rebin_fields(grower_grading_rebin_id, params) # rubocop:disable Metrics/AbcSize
      val = params[:column_value]
      changes_made = changes_made_for(grower_grading_rebin_id)

      case params[:column_name]
      when 'graded_rmt_class_code'
        changes_made['descriptions'][:graded_rmt_class_code] = val
        changes_made[:rmt_class_id] = repo.get_id(:rmt_classes, rmt_class_code: val)
      when 'graded_rmt_size_code'
        changes_made['descriptions'][:graded_rmt_size_code] = val
        changes_made[:rmt_size_id] =  repo.get_id(:rmt_sizes, size_code: val)
      when 'graded_gross_weight'
        changes_made[:gross_weight] =  val
      when 'graded_nett_weight'
        changes_made[:nett_weight] =  val
      end

      repo.transaction do
        repo.update_grower_grading_rebin(grower_grading_rebin_id, changes_made: changes_made)
        log_transaction
      end
      success_response('Updated grower grading rebin', { changes: changes_made })
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= GrowerGradingRepo.new
    end

    def grower_grading_rebin(id)
      repo.find_grower_grading_rebin(id)
    end

    def validate_grower_grading_rebin_params(params)
      GrowerGradingRebinSchema.call(params)
    end

    def changes_made_for(grower_grading_rebin_id)
      changes_made = repo.get(:grower_grading_rebins, grower_grading_rebin_id, :changes_made)
      changes_made.nil? ? { 'descriptions' => {} } : Hash[changes_made]
    end
  end
end
