# frozen_string_literal: true

module RawMaterialsApp
  class PresortStagingRunInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_presort_staging_run(params) # rubocop:disable Metrics/AbcSize
      params[:season_id] = MasterfilesApp::CalendarRepo.new.get_season_id(params[:cultivar_id], Time.now) unless params[:cultivar_id].nil_or_empty?
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
      params[:season_id] = MasterfilesApp::CalendarRepo.new.get_season_id(params[:cultivar_id], Time.now) unless params[:cultivar_id].nil_or_empty?
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
        repo.update_presort_staging_run(id, setup_completed: true, editing: false, setup_completed_at: Time.now)
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
        repo.update_presort_staging_run(id, setup_completed: false, editing: true, setup_uncompleted_at: Time.now)
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

    def activate_run(id) # rubocop:disable Metrics/AbcSize
      resource_id = repo.get(:presort_staging_runs, id, :presort_unit_plant_resource_id)
      return failed_response("Cannot activate presort_run: #{id}. There already exists an active run for this plant") if repo.exists?(:presort_staging_runs, presort_unit_plant_resource_id: resource_id, active: true)

      repo.transaction do
        repo.update_presort_staging_run(id, active: true, activated_at: Time.now)
        log_status(:presort_staging_runs, id, 'ACTIVE')
        log_transaction
      end
      instance = presort_staging_run(id)
      success_response("Presort staging run #{instance.id} has been activated", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def complete_staging(id)
      repo.transaction do
        repo.update_presort_staging_run(id, active: false, staged: true, staged_at: Time.now)
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

    def create_presort_staging_run_child(presort_staging_run_id, params) # rubocop:disable Metrics/AbcSize
      res = validate_presort_staging_run_child_params(params.merge(presort_staging_run_id: presort_staging_run_id, editing: true))
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_presort_staging_run_child(res)
        log_status(:presort_staging_run_children, id, 'EDITING')
        log_transaction
      end
      instance = presort_staging_run_child(id)
      success_response("Created presort staging run child #{instance.id}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { farm_id: ['This presort staging run child already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def activate_child_run(id) # rubocop:disable Metrics/AbcSize
      parent_id = repo.get(:presort_staging_run_children, id, :presort_staging_run_id)
      return failed_response("Cannot activate child_run: #{id}. There already exists an active child_run", parent_id) if repo.exists?(:presort_staging_run_children, presort_staging_run_id: parent_id, active: true)

      repo.transaction do
        repo.update_presort_staging_run_child(id, active: true, editing: false, activated_at: Time.now)
        log_status(:presort_staging_run_children, id, 'ACTIVATED')
        log_transaction
      end
      success_response("Presort staging run #{id} has been activated", parent_id)
    rescue Crossbeams::InfoError => e
      failed_response(e.message, parent_id)
    rescue StandardError => e
      failed_response(e.message, parent_id)
    end

    def complete_child_staging(id)
      parent_id = repo.get(:presort_staging_run_children, id, :presort_staging_run_id)
      repo.transaction do
        repo.update_presort_staging_run_child(id, staged: true, active: false, staged_at: Time.now)
        log_status(:presort_staging_run_children, id, 'STAGED')
        log_transaction
      end
      success_response("Presort staging run #{id} has been completed", parent_id)
    rescue Crossbeams::InfoError => e
      failed_response(e.message, parent_id)
    rescue StandardError => e
      failed_response(e.message, parent_id)
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

    def presort_staging_run_child(id)
      repo.find_presort_staging_run_child_flat(id)
    end

    def validate_presort_staging_run_child_params(params)
      PresortStagingRunChildSchema.call(params)
    end

    def validate_presort_staging_run_params(params)
      PresortStagingRunSchema.call(params)
    end
  end
end
