# frozen_string_literal: true

module RawMaterialsApp
  class PresortGrowerGradingBinInteractor < BaseInteractor
    def create_presort_grower_grading_bin(params) # rubocop:disable Metrics/AbcSize
      res = validate_presort_grower_grading_bin_params(include_created_by_in_changeset(params))
      return validation_failed_response(res) if res.failure?

      existing_id = repo.look_for_existing_grading_bin_id(res)
      if existing_id
        instance = presort_grower_grading_bin(existing_id)
        return success_response('Found existing presort grading bin', instance)
      end

      id = nil
      repo.transaction do
        id = repo.create_presort_grower_grading_bin(res)
        log_status(:presort_grower_grading_bins, id, 'CREATED')
        log_transaction
      end
      instance = presort_grower_grading_bin(id)
      success_response('Created presort grower grading bin', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_presort_grower_grading_bin(id, params)
      res = EditPresortGrowerGradingBinSchema.call(include_updated_by_in_changeset(params))
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_presort_grower_grading_bin(id, res)
        log_transaction
      end
      instance = presort_grower_grading_bin(id)
      success_response('Updated presort grower grading bin', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_presort_grower_grading_bin(id)
      repo.transaction do
        repo.delete_presort_grower_grading_bin(id)
        log_status(:presort_grower_grading_bins, id, 'DELETED')
        log_transaction
      end
      success_response('Deleted presort grower grading bin')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete presort grower grading bin. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PresortGrowerGradingBin.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def inline_edit_bin_fields(grading_bin_id, params) # rubocop:disable Metrics/AbcSize
      val = params[:column_value]
      attrs = case params[:column_name]
              when 'rmt_class_code'
                { rmt_class_id:  repo.get_id(:rmt_classes, rmt_class_code: val) }
              when 'rmt_size_code'
                { rmt_size_id:  repo.get_id(:rmt_sizes, size_code: val) }
              when 'colour'
                { colour_percentage_id:  repo.get_id(:colour_percentages, colour_percentage: val, commodity_id: repo.get_grading_pool_commodity_id(grading_bin_id)) }
              when 'rmt_bin_weight'
                { rmt_bin_weight:  val }
              end

      attrs[:graded] = true
      repo.transaction do
        repo.update_presort_grower_grading_bin(grading_bin_id, include_updated_by_in_changeset(attrs))
        log_transaction
      end

      instance = presort_grower_grading_bin(grading_bin_id)
      success_response('Updated grower grading bin', { changes: { rmt_class_code: instance[:rmt_class_code],
                                                                  rmt_size_code: instance[:rmt_size_code],
                                                                  colour: instance[:colour],
                                                                  rmt_bin_weight: instance[:rmt_bin_weight],
                                                                  graded: instance[:graded],
                                                                  adjusted_weight: instance[:adjusted_weight] } })
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= PresortGrowerGradingRepo.new
    end

    def presort_grower_grading_bin(id)
      repo.find_presort_grower_grading_bin(id)
    end

    def validate_presort_grower_grading_bin_params(params)
      NewPresortGrowerGradingBinSchema.call(params)
    end
  end
end
