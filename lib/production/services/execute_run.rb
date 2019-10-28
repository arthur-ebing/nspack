# frozen_string_literal: true

module ProductionApp
  class ExecuteRun < BaseService
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
                        comment: changeset[:active_run_status],
                        user_name: user_name)
      end
      success_response('Run is executing')
    end

    private

    def create_carton_label_cache # rubocop:disable Metrics/AbcSize
      cache = {}
      repo.allocated_setup_keys(production_run.id).each do |rec|
        cache[rec[:system_resource_code]] = {
          print_command: print_command_for(rec[:product_resource_allocation_id], rec[:label_template_name]),
          setup_data: rec[:setup_data],
          production_run_data: cache_run.merge(product_resource_allocation_id: rec[:product_resource_allocation_id],
                                               resource_id: rec[:resource_id],
                                               label_name: rec[:label_template_name])
        }
      end
      FileUtils.mkpath(File.join(ENV['ROOT'], 'tmp', 'run_cache'))
      File.open(File.join(ENV['ROOT'], 'tmp', 'run_cache', "line_#{production_run.production_line_id}.yml"), 'w') { |f| f << cache.to_yaml }
    end

    def cache_run # rubocop:disable Metrics/AbcSize
      @cache_run ||= {
        production_run_id: production_run[:id],
        farm_id: production_run[:farm_id],
        puc_id: production_run[:puc_id],
        orchard_id: production_run[:orchard_id],
        cultivar_group_id: production_run[:cultivar_group_id],
        cultivar_id: production_run[:cultivar_id],
        packhouse_resource_id: production_run[:packhouse_resource_id],
        production_line_id: production_run[:production_line_id],
        season_id: production_run[:season_id]
      }
    end

    def print_command_for(product_resource_allocation_id, label_template_name)
      instance = messcada_repo.allocated_product_setup_label_printing_instance(product_resource_allocation_id)
      res = LabelPrintingApp::PrintCommandForLabel.call(label_template_name, instance)
      raise res.message unless res.success

      res.instance.print_command
    end

    def do_labeling?
      @do_labeling ||= begin
                         res = repo.find_production_runs_for_line_in_state(production_run.production_line_id, running: true, labeling: true)
                         !res.success
                       end
    end

    def build_changeset
      {
        tipping: true,
        running: true,
        labeling: do_labeling?,
        started_at: Time.now,
        active_run_stage: do_labeling? ? 'TIPPING_AND_LABELING' : 'TIPPING_ONLY'
      }
    end
  end
end
