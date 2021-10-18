# frozen_string_literal: true

module RawMaterialsApp
  class PresortStagingRunInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_presort_staging_run(params) # rubocop:disable Metrics/AbcSize
      params[:season_id] = calendar_repo.get_season_id(params[:cultivar_id], Time.now) unless params[:cultivar_id].nil_or_empty?
      params[:editing] = true
      legacy = AppConst::CR_RMT.presort_legacy_data_fields.map { |f| [f, params[f]] }
      params[:legacy_data] = Hash[legacy] unless legacy.empty?
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
      params[:supplier_id] = repo.get(:presort_staging_runs, id, :supplier_id) unless params.key?(:supplier_id)
      params[:season_id] = calendar_repo.get_season_id(params[:cultivar_id], Time.now) unless params[:cultivar_id].nil_or_empty?
      legacy = AppConst::CR_RMT.presort_legacy_data_fields.map { |f| [f, params[f]] }
      params[:legacy_data] = Hash[legacy] unless legacy.empty?
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
      res = TaskPermissionCheck::PresortStagingRun.call(:complete_setup, id)
      return res unless res.success

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

    def activate_run(id)
      res = TaskPermissionCheck::PresortStagingRun.call(:activate_run, id)
      return res unless res.success

      repo.transaction do
        repo.update_presort_staging_run(id, running: true, activated_at: Time.now)
        log_status(:presort_staging_runs, id, 'RUNNING')
        log_transaction
      end
      instance = presort_staging_run(id)
      success_response("Presort staging run #{instance.id} has been activated", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def complete_staging(id) # rubocop:disable Metrics/AbcSize
      res = TaskPermissionCheck::PresortStagingRun.call(:complete_staging, id)
      return res unless res.success

      repo.transaction do
        active_child_id = repo.get_value(:presort_staging_run_children, :id, presort_staging_run_id: id, running: true)
        repo.update_presort_staging_run(id, running: false, staged: true, staged_at: Time.now)
        log_status(:presort_staging_runs, id, 'STAGED')
        repo.update_presort_staging_run_child(active_child_id, staged: true, running: false, staged_at: Time.now)
        log_status(:presort_staging_run_children, active_child_id, 'STAGED')
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
      res = TaskPermissionCheck::PresortStagingRun.call(:delete, id)
      return res unless res.success

      repo.transaction do
        repo.delete_presort_staging_run(id)
        log_status(:presort_staging_runs, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted presort staging run #{id}")
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
      res = TaskPermissionCheck::PresortStagingRunChild.call(:activate_child, id)
      return res unless res.success

      repo.transaction do
        repo.update_presort_staging_run_child(id, running: true, editing: false, activated_at: Time.now)
        log_status(:presort_staging_run_children, id, 'RUNNING')
        log_transaction
      end
      success_response("Presort staging run #{id} has been activated", res.instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message, res.instance)
    rescue StandardError => e
      failed_response(e.message, res.instance)
    end

    def complete_child_staging(id)
      parent_id = repo.get(:presort_staging_run_children, id, :presort_staging_run_id)
      repo.transaction do
        repo.update_presort_staging_run_child(id, staged: true, running: false, staged_at: Time.now)
        log_status(:presort_staging_run_children, id, 'STAGED')
        log_transaction
      end
      success_response("Presort staging run #{id} has been completed", parent_id)
    rescue Crossbeams::InfoError => e
      failed_response(e.message, parent_id)
    rescue StandardError => e
      failed_response(e.message, parent_id)
    end

    def delete_presort_staging_run_child(id) # rubocop:disable Metrics/AbcSize
      parent_id = repo.get(:presort_staging_run_children, id, :presort_staging_run_id)
      repo.transaction do
        repo.delete_presort_staging_run_child(id)
        log_status(:presort_staging_run_children, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted presort staging run child #{id}", parent_id)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete presort staging run child. It is still referenced#{e.message.partition('referenced').last}")
    end

    def stage_bins(params, request_path)
      log_request(params, request_path)
      bins = [params[:bin1], params[:bin2], params[:bin3]]
      plant_resource = params[:unit]
      MesscadaApp::BinStaging.call(bins, plant_resource)
    end

    def staging_override_provided(params, request_path) # rubocop:disable Metrics/AbcSize
      log_request(params, "#{request_path}answer=#{params[:answer]}")
      if params[:answer] == 'yes'
        bins = [params[:bin1], params[:bin2], params[:bin3]]
        plant_resource = params[:unit]
        MesscadaApp::StagingOverride.call(bins, plant_resource)
      else
        bin_results = [{ bin_num: params[:bin1], bin_item: 1, status: 'OVERRIDE_CANCELLED', msg: 'bin override has been cancelled' }]
        bin_results << { bin_num: params[:bin2], bin_item: 2, status: 'OVERRIDE_CANCELLED', msg: 'bin override has been cancelled' } if params[:bin2]
        bin_results << { bin_num: params[:bin3], bin_item: 3, status: 'OVERRIDE_CANCELLED', msg: 'bin override has been cancelled' } if params[:bin3]
        res = MesscadaApp::StageBins.result(bin_results)
        success_response('Override Cancelled', res)
      end
    end

    def bin_tipped(params, request_path)
      AppConst::PRESORT_BIN_TIPPED_LOG.info("#{request_path}&bin=#{params[:bin]}")
      MesscadaApp::PresortBinTipped.call(params[:bin])
    end

    def bin_created(params, request_path)
      AppConst::PRESORT_BIN_CREATED_LOG.info("#{request_path}&bin=#{params[:bin]}")
      MesscadaApp::PresortBinCreated.call(params[:bin], params[:unit])
    end

    def log_request(params, msq)
      msg = "#{msq}&unit=#{params[:unit]}&bin1=#{params[:bin1]}"
      msg += "&bin2=#{params[:bin2]}" if params[:bin2]
      msg += "&bin3=#{params[:bin3]}" if params[:bin3]
      AppConst::BIN_STAGING_LOG.info(msg)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PresortStagingRun.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= PresortStagingRunRepo.new
    end

    def calendar_repo
      MasterfilesApp::CalendarRepo.new
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
