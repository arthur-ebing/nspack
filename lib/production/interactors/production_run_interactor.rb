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
      repo.allocate_product_setup(product_resource_allocation_id, params[:column_value])
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
  end
end
