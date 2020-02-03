# frozen_string_literal: true

module ProductionApp
  class CompleteRun < BaseService
    attr_reader :production_run, :repo, :messcada_repo, :user_name, :tipping_run_id

    def initialize(id, user_name)
      @repo = ProductionRunRepo.new
      @production_run = repo.find_production_run(id)
      @user_name = user_name
      @tipping_run_id = repo.tipping_run_for_line(production_run.production_line_id)
    end

    def call # rubocop:disable Metrics/AbcSize
      changeset = build_changeset
      repo.transaction do
        repo.update_production_run(production_run.id, changeset)
        delete_carton_label_cache

        repo.log_status(:production_runs, production_run.id,
                        'COMPLETED',
                        user_name: user_name)
      end
      if tipping_run_id.nil?
        success_response('Run has been completed', this_run: changeset.to_h.merge(status: 'COMPLETED'))
      else
        res = ExecuteRun.call(tipping_run_id, user_name, extend_tipping_run: true) unless tipping_run_id.nil?
        success_response('Run has been completed and tipping run has begun labeling', this_run: changeset.to_h.merge(status: 'COMPLETED'), other_run: res.instance[:this_run])
      end
    end

    private

    def delete_carton_label_cache
      FileUtils.mkpath(AppConst::LABELING_CACHED_DATA_FILEPATH)
      File.delete(File.join(AppConst::LABELING_CACHED_DATA_FILEPATH, "line_#{production_run.production_line_id}.yml"))
    end

    def build_changeset
      {
        tipping: false,
        running: false,
        labeling: false,
        completed: true,
        completed_at: Time.now,
        active_run_stage: nil
      }
    end
  end
end
