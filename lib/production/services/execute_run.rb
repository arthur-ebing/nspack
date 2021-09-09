# frozen_string_literal: true

require_relative './execute_label_cache'

module ProductionApp
  class ExecuteRun < BaseService
    include ExecuteLabelCache

    attr_reader :production_run, :repo, :messcada_repo, :user_name, :extend_tipping_run

    def initialize(id, user_name, extend_tipping_run: false)
      @repo = ProductionRunRepo.new
      @messcada_repo = MesscadaApp::MesscadaRepo.new
      @production_run = repo.find_production_run(id)
      @user_name = user_name
      @extend_tipping_run = extend_tipping_run
    end

    def call # rubocop:disable Metrics/AbcSize
      err = repo.validate_run_bin_tipping_criteria_and_control_data(@production_run.id)
      return failed_response(err, running: true, this_run: { tipping: production_run.tipping, setup_complete: production_run.setup_complete, reconfiguring: production_run.reconfiguring, labeling: production_run.labeling, running: production_run.running, status: repo.production_run_status(production_run.id), active_run_stage: production_run.active_run_stage, id: production_run.id, colour_rule: 'ok' }) if err

      changeset = build_changeset
      repo.transaction do
        repo.update_production_run(production_run.id, changeset)
        create_carton_label_cache if do_labeling?

        repo.log_status(:production_runs, production_run.id,
                        'RUNNING',
                        comment: changeset[:active_run_stage],
                        user_name: user_name)

        MesscadaApp::Job::NotifyProductionRunResourceStates.enqueue(production_run.id, user_name) if AppConst::CR_PROD.run_provides_button_captions?
        # Notify active setups page that the page might need to be reloaded:
        work = [{ reload_page: { message: 'You might need to reload this page - a new run has been executed.' } }]
        send_bus_message_to_page(work, 'product_setups_on_runs/with_params')
      end
      success_response('Run is executing', this_run: changeset.to_h.merge(status: 'RUNNING',
                                                                          id: production_run.id,
                                                                          colour_rule: 'ok',
                                                                          allocation_required: false,
                                                                          view_allocs: true))
    end

    private

    def do_labeling?
      @do_labeling ||= begin
                         if extend_tipping_run
                           true
                         else
                           res = repo.find_production_runs_for_line_in_state(production_run.production_line_id, running: true, labeling: true)
                           if res.success
                             res.instance.include?(production_run.id) ? true : false
                           else
                             true
                           end
                         end
                       end
    end

    def run_is_already_tipping?
      production_run.tipping
    end

    def active_stage
      return 'TIPPING_AND_LABELING' if extend_tipping_run

      if run_is_already_tipping?
        'LABELING'
      elsif do_labeling?
        'TIPPING_AND_LABELING'
      else
        'TIPPING_ONLY'
      end
    end

    def build_changeset
      tipping = extend_tipping_run
      tipping ||= !run_is_already_tipping?

      changeset = {
        running: true,
        tipping: tipping,
        setup_complete: true,
        reconfiguring: false,
        labeling: do_labeling?,
        active_run_stage: active_stage
      }

      changeset[:started_at] = Time.now unless run_is_already_tipping?
      changeset[:re_executed_at] = Time.now unless production_run.started_at.nil?
      changeset
    end
  end
end
