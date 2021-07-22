# frozen_string_literal: true

module RawMaterialsApp
  class PresortStagingRunInteractor < BaseInteractor
    def create_presort_staging_run(params) # rubocop:disable Metrics/AbcSize
      params[:season_id] = MasterfilesApp::CalendarRepo.new.get_season_id(params[:cultivar_id], Time.now)
      params[:editing] = true
      params[:legacy_data] = { ripe_point_code: params[:ripe_point_code], track_indicator_code: params[:track_indicator_code] } if AppConst::CLIENT_CODE == 'kr'
      res = validate_presort_staging_run_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_presort_staging_run(res)
        log_status(:presort_staging_runs, id, 'EDITING')
        log_transaction
      end
      instance = presort_staging_run(id)
      success_response("Created presort staging run #{instance.id}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { id: ['This presort staging run already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_presort_staging_run(id, params) # rubocop:disable Metrics/AbcSize
      params[:season_id] = MasterfilesApp::CalendarRepo.new.get_season_id(params[:cultivar_id], Time.now)
      # params[:editing] = true
      params[:legacy_data] = { ripe_point_code: params[:ripe_point_code], track_indicator_code: params[:track_indicator_code] } if AppConst::CLIENT_CODE == 'kr'
      res = validate_presort_staging_run_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_presort_staging_run(id, res)
        log_transaction
      end
      instance = presort_staging_run(id)
      success_response("Updated presort staging run #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def complete_setup(id)
      repo.transaction do
        repo.update_presort_staging_run(id, completed: true, editing: false, completed_at: Time.now)
        log_status(:presort_staging_runs, id, 'COMPLETED')
        log_transaction
      end
      instance = presort_staging_run(id)
      success_response("Presort staging run #{instance.id} has been completed", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def uncomplete_setup(id)
      repo.transaction do
        repo.update_presort_staging_run(id, completed: false, editing: true, uncompleted_at: Time.now)
        log_status(:presort_staging_runs, id, 'UNCOMPLETED')
        log_transaction
      end
      instance = presort_staging_run(id)
      success_response("Presort staging run #{instance.id} has been uncompleted", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def complete_staging(id)
      repo.transaction do
        repo.update_presort_staging_run(id, staged: true, staged_at: Time.now)
        log_status(:presort_staging_runs, id, 'STAGED')
        log_transaction
      end
      instance = presort_staging_run(id)
      success_response("Presort staging run #{instance.id} has been staged", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def delete_presort_staging_run(id) # rubocop:disable Metrics/AbcSize
      name = presort_staging_run(id).id
      repo.transaction do
        repo.delete_presort_staging_run(id)
        log_status(:presort_staging_runs, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted presort staging run #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete presort staging run. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PresortStagingRun.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= PresortStagingRunRepo.new
    end

    def presort_staging_run(id)
      repo.find_presort_staging_run_flat(id)
    end

    def validate_presort_staging_run_params(params)
      PresortStagingRunSchema.call(params)
    end
  end
end
