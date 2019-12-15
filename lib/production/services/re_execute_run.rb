# frozen_string_literal: true

require_relative './execute_label_cache'

module ProductionApp
  class ReExecuteRun < BaseService
    include ExecuteLabelCache

    attr_reader :production_run, :repo, :messcada_repo, :user_name

    def initialize(id, user_name)
      @repo = ProductionRunRepo.new
      @messcada_repo = MesscadaApp::MesscadaRepo.new
      @production_run = repo.find_production_run(id)
      @user_name = user_name
    end

    def call # rubocop:disable Metrics/AbcSize
      changeset = build_changeset
      repo.transaction do
        repo.update_production_run(production_run.id, changeset)
        create_carton_label_cache if do_labeling?

        repo.log_status(:production_runs, production_run.id,
                        'RUNNING',
                        comment: changeset[:active_run_stage],
                        user_name: user_name)
        # Kick off a job to send the new button labels to MesServer
        # get all CLM buttons for a line and if not allocated, set "unallocated" else set to the count.
        # get all BVM buttons for a line and if not allocated, set "unallocated" else set to the tare.
        # Separate calls for JF? or all in one XML string?
      end
      success_response('Run is executing', changeset.to_h.merge(status: "RUNNING #{changeset[:active_run_stage]}"))
    end

    private

    def do_labeling?
      @do_labeling ||= production_run.labeling || begin
                         res = repo.find_production_runs_for_line_in_state(production_run.production_line_id, running: true, labeling: true)
                         if res.success
                           res.instance.include?(production_run.id) ? true : false
                         else
                           true
                         end
                       end
    end

    def active_stage
      if do_labeling?
        if production_run.tipping
          'TIPPING_AND_LABELING'
        else
          'LABELING'
        end
      else
        'TIPPING_ONLY'
      end
    end

    def build_changeset
      changeset = {
        running: true,
        tipping: production_run.tipping,
        setup_complete: true,
        reconfiguring: false,
        labeling: do_labeling?,
        active_run_stage: active_stage,
        re_executed_at: Time.now
      }

      changeset
    end
  end
end
