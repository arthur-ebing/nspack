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
      err = repo.validate_run_bin_tipping_criteria_and_control_data(@production_run.id)
      return failed_response(err, tipping: production_run.tipping, setup_complete: production_run.setup_complete, reconfiguring: production_run.reconfiguring, labeling: production_run.labeling, running: production_run.running, status: repo.production_run_status(production_run.id), active_run_stage: production_run.active_run_stage, id: production_run.id, colour_rule: 'ok') if err

      changeset = build_changeset
      repo.transaction do
        repo.update_production_run(production_run.id, changeset)
        create_carton_label_cache if do_labeling?

        repo.log_status(:production_runs, production_run.id,
                        'RUNNING',
                        comment: changeset[:active_run_stage],
                        user_name: user_name)

        # MesscadaApp::Job::NotifyProductionRunResourceStates.enqueue(production_run.id) if AppConst::CLM_BUTTON_CAPTION_FORMAT || AppConst::PROVIDE_PACK_TYPE_AT_VERIFICATION
        MesscadaApp::Job::NotifyProductionRunResourceStates.enqueue(production_run.id, user_name) if AppConst::CR_PROD.run_provides_button_captions?
        # Notify active setups page that the page might need to be reloaded:
        work = [{ reload_page: { message: 'You might need to reload this page - a new run has been executed.' } }]
        send_bus_message_to_page(work, 'product_setups_on_runs/with_params')
      end
      success_response('Run is executing', changeset.to_h.merge(status: "RUNNING #{changeset[:active_run_stage]}",
                                                                colour_rule: 'ok',
                                                                allocation_required: false,
                                                                view_allocs: true))
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
        labeling: do_labeling?,
        reconfiguring: false,
        setup_complete: true,
        active_run_stage: active_stage,
        re_executed_at: Time.now
      }

      changeset
    end
  end
end
