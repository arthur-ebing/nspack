# frozen_string_literal: true

module ProductionApp
  class ProductionRunInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_production_run(params) # rubocop:disable Metrics/AbcSize
      res = validate_new_production_run_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_production_run(res)
        log_status('production_runs', id, 'CREATED')
        log_transaction
      end
      instance = production_run(id)
      success_response("Created production run #{instance.active_run_stage}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { active_run_stage: ['This production run already exists'] }))
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
      instance = production_run(id)
      success_response("Updated production run #{instance.active_run_stage}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_production_run(id)
      name = production_run(id).active_run_stage
      repo.transaction do
        repo.delete_production_run(id)
        log_status('production_runs', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted production run #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
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
      instance = production_run_with_assoc(id)
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
    def print_carton_label(id, product_setup_id, params)
      res = validate_print_carton(params)
      return validation_failed_response(res) unless res.messages.empty?
      return mixed_validation_failed_response(res, messages: { no_of_prints: ["cannot be more than #{AppConst::BATCH_PRINT_MAX_LABELS}"] }) if res[:no_of_prints] > AppConst::BATCH_PRINT_MAX_LABELS

      MesscadaApp::BatchPrintCartonLabels.call(id, product_setup_id, res[:label_template_id], params)
      success_response('Label sent to printer', id: id, product_setup_id: product_setup_id)
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

    def production_run_with_assoc(id)
      repo.find_production_run_with_assoc(id)
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

        required(:printer, :integer).filled(:int?)
        required(:label_template_id, :integer).filled(:int?)
        required(:no_of_prints, :integer).filled(:int?, gt?: 0)
      end.call(params)
    end
  end
end
