# frozen_string_literal: true

module ProductionApp
  class CompleteRun < BaseService
    attr_reader :production_run, :repo, :messcada_repo, :user_name

    def initialize(id, user_name)
      @repo = ProductionRunRepo.new
      @production_run = repo.find_production_run(id)
      @user_name = user_name
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
      success_response('Run has been completed', changeset.to_h.merge(status: 'COMPLETED'))
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
