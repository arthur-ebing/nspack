# frozen_string_literal: true

module ProductionApp
  class ProductionRunInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_production_run(params) # rubocop:disable Metrics/AbcSize
      res = validate_new_production_run_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_production_run(res)
        repo.create_production_run_stats(id)
        log_status('production_runs', id, 'CREATED')
        log_transaction
      end
      instance = production_run_flat(id)
      success_response("Created production run #{instance.production_run_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { packhouse_id: ['This production run already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_production_run(id, params)
      res = validate_production_run_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_production_run(id, res)
        log_transaction
      end
      instance = production_run_flat(id)
      success_response("Updated production run #{instance.production_run_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_production_run(id) # rubocop:disable Metrics/AbcSize
      raise Crossbeams::TaskNotPermittedError, 'Run cannot be deleted at this stage' if production_run(id).setup_complete || production_run(id).reconfiguring

      name = production_run_flat(id).production_run_code
      repo.transaction do
        repo.delete_product_resource_allocations(id)
        repo.delete_production_run_stats(id)
        repo.delete_production_run(id)
        log_status('production_runs', id, 'DELETED')
        log_transaction
      end

      success_response("Deleted production run #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def clone_production_run(id)
      new_id = nil
      repo.transaction do
        new_id = repo.clone_production_run(id)
        repo.create_production_run_stats(new_id)
        log_status('production_runs', new_id, 'CLONED', comment: "from run id #{id}")
        log_transaction
      end
      instance = production_run_flat(new_id)
      success_response("Cloned as new production run #{instance.production_run_code}",
                       instance)
    end

    def selected_template(id)
      success_response('ok', repo.find_hash(:product_setup_templates, id))
    end

    def update_template(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_production_run_template_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      current_template = production_run(id).product_setup_template_id
      repo.transaction do
        repo.update_production_run(id, res)
        log_status('production_runs', id, 'EDITING') if current_template.nil?
        log_transaction
      end
      instance = production_run_flat(id)
      success_response("Updated production run #{instance.production_run_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def prepare_run_allocation_targets(id)
      assert_permission!(:allocate_setups, id)
      repo.prepare_run_allocation_targets(id)
    end

    def allocate_product_setup(product_resource_allocation_id, params)
      res = repo.allocate_product_setup(product_resource_allocation_id, params[:column_value])
      res.instance = { changes: { product_setup_id: res.instance[:product_setup_id] } }
      res
    end

    def label_for_allocation(product_resource_allocation_id, params)
      res = repo.label_for_allocation(product_resource_allocation_id, params[:column_value])
      res.instance = { changes: { label_template_name: res.instance[:label_template_name] } }
      res
    end

    def inline_edit_alloc(product_resource_allocation_id, params)
      if params[:column_name] == 'product_setup_code'
        allocate_product_setup(product_resource_allocation_id, params)
      elsif params[:column_name] == 'label_template_name'
        label_for_allocation(product_resource_allocation_id, params)
      else
        failed_response(%(There is no handler for changed column "#{params[:column_name]}"))
      end
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::ProductionRun.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def re_configure_run(id)
      assert_permission!(:re_configure, id)
      repo.transaction do
        repo.update_production_run(id, reconfiguring: true, setup_complete: false)
        log_status('production_runs', id, 'RE-CONFiGURING')
        log_transaction
      end
      success_response('Run can be re-configured')
    end

    def prepare_to_complete_run(id)
      assert_permission!(:complete_run_stage, id)
      success_response('Labeling stage will finish and run will complete')
    end

    def prepare_to_complete_stage(id)
      assert_permission!(:complete_run_stage, id)
      message = case production_run(id).next_stage
                when :complete
                  'Labeling stage will finish and run will complete'
                when :labeling
                  'The tipping stage will finish and the labeling stage will begin'
                else
                  return failed_response('This run is not in a valid state')
                end

      success_response(message)
    end

    def complete_run(id)
      CompleteRun.call(id, @user.user_name)
    end

    def complete_stage(id)
      case production_run(id).next_stage
      when :complete
        CompleteRun.call(id, @user.user_name)
      when :labeling
        ExecuteRun.call(id, @user.user_name)
      else
        failed_response('Incorrect state')
      end
    end

    def lines_for_packhouse(params)
      res = validate_changed_value_as_int(params)
      return validation_failed_response(res) unless res.messages.empty?
      return success_response('ok', []) if res[:changed_value].nil?

      success_response('ok', ResourceRepo.new.packhouse_lines(res[:changed_value]))
    end

    def change_for_farm(params)
      res = validate_changed_value_as_int(params)
      return validation_failed_response(res) unless res.messages.empty?

      instance = { pucs: [], orchards: [], cultivar_groups: [], cultivars: [], seasons: [] }
      return success_response('ok', instance) if res[:changed_value].nil?

      instance[:pucs] = farm_repo.selected_farm_pucs(res[:changed_value])

      success_response('ok', instance)
    end

    def change_for_puc(params)
      res = validate_changed_value_as_int(params)
      return validation_failed_response(res) unless res.messages.empty?

      instance = { orchards: [], cultivar_groups: [], cultivars: [], seasons: [] }
      return success_response('ok', instance) if res[:changed_value].nil?

      instance[:orchards] = farm_repo.selected_farm_orchard_codes(params[:production_run_farm_id], res[:changed_value])
      instance[:orchards].unshift(['', ''])

      success_response('ok', instance)
    end

    def change_for_orchard(params) # rubocop:disable Metrics/AbcSize
      res = validate_changed_value_as_int(params)
      return validation_failed_response(res) unless res.messages.empty?

      instance = { cultivar_groups: [], cultivars: [], seasons: [] }
      if res[:changed_value].nil?
        instance[:cultivar_groups] = cultivar_repo.for_select_cultivar_groups
      else
        orchard = farm_repo.find_orchard(res[:changed_value])
        cultivar_group_ids = cultivar_repo.all_hash(:cultivars, id: orchard.cultivar_ids.to_a).map { |rec| rec[:cultivar_group_id] }
        instance[:cultivar_groups] = if cultivar_group_ids.empty?
                                       cultivar_repo.for_select_cultivar_groups
                                     else
                                       cultivar_repo.for_select_cultivar_groups(where: { id: cultivar_group_ids })
                                     end
        instance[:cultivars] = cultivar_repo.for_select_cultivars(where: { id: orchard.cultivar_ids.to_a })
        instance[:cultivars].unshift(['', '']) # if mixed_cult
      end

      success_response('ok', instance)
    end

    def change_for_cultivar_group(params)
      res = validate_changed_value_as_int(params)
      return validation_failed_response(res) unless res.messages.empty?

      instance = { cultivars: [], seasons: [] }
      instance[:cultivars] = cultivar_repo.for_select_cultivars(where: { cultivar_group_id: res[:changed_value] })
      instance[:cultivars].unshift(['', '']) # if mixed_cult
      instance[:seasons] = MasterfilesApp::CalendarRepo.new.for_select_seasons_for_cultivar_group(res[:changed_value])

      success_response('ok', instance)
    end

    def preview_allocation_carton_label(product_resource_allocation_id)
      alloc = repo.find_hash(:product_resource_allocations, product_resource_allocation_id)
      return failed_response('Please choose a product setup') unless alloc[:product_setup_id]
      return failed_response('Please choose a label template') unless alloc[:label_template_id]

      instance = messcada_repo.allocated_product_setup_label_printing_instance(product_resource_allocation_id)
      label = repo.find_hash(:label_templates, alloc[:label_template_id])[:label_template_name]
      LabelPrintingApp::PreviewLabel.call(label, instance)
    end

    # create carton_print_repo?
    def print_carton_label(id, product_setup_id, request_ip, params)
      res = validate_print_carton(params)
      return validation_failed_response(res) unless res.messages.empty?
      return mixed_validation_failed_response(res, messages: { no_of_prints: ["cannot be more than #{AppConst::BATCH_PRINT_MAX_LABELS}"] }) if res[:no_of_prints] > AppConst::BATCH_PRINT_MAX_LABELS

      MesscadaApp::BatchPrintCartonLabels.call(id, product_setup_id, res[:label_template_id], request_ip, params)
      success_response('Label sent to printer', id: id, product_setup_id: product_setup_id)
    end

    def mark_setup_as_complete(id)
      repo.transaction do
        repo.update_production_run(id, setup_complete: true)
        log_status('production_runs', id, 'SETUP_COMPLETED')
        log_transaction
      end
    end

    def execute_run(id)
      ExecuteRun.call(id, @user.user_name)
    end

    # Read the user profile to get line_no & then find active labeling run for that line
    def active_run_id_for_user(current_user)
      return nil unless current_user&.profile
      return nil if current_user.profile['packhouse_line_id'].nil_or_empty?

      repo.labeling_run_for_line(current_user.profile['packhouse_line_id'])
    end

    private

    def repo
      @repo ||= ProductionRunRepo.new
    end

    def farm_repo
      @farm_repo ||= MasterfilesApp::FarmRepo.new
    end

    def cultivar_repo
      @cultivar_repo ||= MasterfilesApp::CultivarRepo.new
    end

    def product_setup_repo
      @product_setup_repo ||= ProductionApp::ProductSetupRepo.new
    end

    def messcada_repo
      @messcada_repo ||= MesscadaApp::MesscadaRepo.new
    end

    def production_run(id)
      repo.find_production_run(id)
    end

    def production_run_flat(id)
      repo.find_production_run_flat(id)
    end

    def validate_new_production_run_params(params)
      ProductionRunNewSchema.call(params)
    end

    def validate_production_run_params(params)
      ProductionRunSchema.call(params)
    end

    def validate_production_run_template_params(params)
      ProductionRunTemplateSchema.call(params)
    end

    def validate_print_carton(params)
      Dry::Validation.Params do
        configure { config.type_specs = true }

        optional(:printer, :integer).filled(:int?)
        required(:label_template_id, :integer).filled(:int?)
        required(:no_of_prints, :integer).filled(:int?, gt?: 0)
      end.call(params)
    end
  end
end
