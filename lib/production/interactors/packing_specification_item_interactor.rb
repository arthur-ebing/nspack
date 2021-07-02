# frozen_string_literal: true

module ProductionApp
  class PackingSpecificationItemInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def refresh_packing_specification_items # rubocop:disable Metrics/AbcSize
      repo.select_values(:product_setup_templates, :id).each do |product_setup_template_id|
        product_setup_ids = repo.select_values(:product_setups,
                                               :id,
                                               { product_setup_template_id: product_setup_template_id })
        existing_ids = repo.select_values(:packing_specification_items,
                                          :product_setup_id)
        (product_setup_ids - existing_ids).each do |product_setup_id|
          create_packing_specification_item(
            product_setup_id: product_setup_id,
            pm_bom_id: repo.get(:product_setups, product_setup_id, :pm_bom_id),
            pm_mark_id: repo.get(:product_setups, product_setup_id, :pm_mark_id)
          )
        end
      end
      success_response('Created packing specification items')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_packing_specification_item(params) # rubocop:disable Metrics/AbcSize
      res = validate_packing_specification_item_params(params)
      return validation_failed_response(res) if res.failure?

      id = repo.look_for_existing_packing_specification_item_id(res)
      if id
        instance = packing_specification_item(id)
        success_response("Found existing packing specification item #{instance.description}", instance)
      end

      repo.transaction do
        id = repo.create_packing_specification_item(res)
        check!(:create, id)
        ProductionApp::Job::CalculateExtendedFgCodesForPackingSpecs.enqueue(id) if AppConst::CR_FG.lookup_extended_fg_code?

        log_status(:packing_specification_items, id, 'CREATED')
        log_transaction
      end
      instance = packing_specification_item(id)
      success_response("Created packing specification item #{instance.description}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { pm_bom_id: ['This packing specification item already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_packing_specification_item(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_packing_specification_item_params(params)
      return validation_failed_response(res) if res.failure?

      existing_id = repo.look_for_existing_packing_specification_item_id(res)
      if existing_id
        instance = packing_specification_item(existing_id)
        success_response("Found existing packing specification item #{instance.description}", instance)
      end

      repo.transaction do
        repo.update_packing_specification_item(id, res)
        check!(:edit, id)
        ProductionApp::Job::CalculateExtendedFgCodesForPackingSpecs.enqueue(id) if AppConst::CR_FG.lookup_extended_fg_code?

        log_transaction
      end
      instance = packing_specification_item(id)
      success_response("Updated packing specification item #{instance.description}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def inline_update_packing_specification_item(id, params)
      repo.transaction do
        repo.inline_update_packing_specification_item(id, params)
        check!(:edit, id)

        log_transaction
      end

      instance = packing_specification_item(id)
      success_response('Updated packing specification item', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_packing_specification_item(id)
      name = packing_specification_item(id).description
      repo.transaction do
        repo.delete_packing_specification_item(id)
        log_status(:packing_specification_items, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted packing specification item #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete packing specification item. It is still referenced#{e.message.partition('referenced').last}")
    end

    def activate_packing_specification_item(id)
      repo.transaction do
        repo.activate(:packing_specification_items, id)
        log_status(:packing_specification_items, id, 'ACTIVATED')
        log_transaction
      end
      instance = packing_specification_item(id)
      success_response("Activated packing specification item #{instance.description}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def deactivate_packing_specification_item(id)
      repo.transaction do
        repo.deactivate(:packing_specification_items, id)
        log_status(:packing_specification_items, id, 'DEACTIVATED')
        log_transaction
      end
      instance = packing_specification_item(id)
      success_response("De-activated packing specification item #{instance.description}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def refresh_extended_fg_code(id)
      repo.transaction do
        ProductionApp::CalculateExtendedFgCodesForPackingSpecs.call(id)
      end
      success_response('Updated Extended FG code')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PackingSpecificationItem.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def check!(task, id = nil)
      res = TaskPermissionCheck::PackingSpecificationItem.call(task, id)
      raise Crossbeams::InfoError, res.message unless res.success
    end

    def packing_specification_item(id)
      repo.find_packing_specification_item(id)
    end

    def for_select_pm_marks(where: {})
      MasterfilesApp::BomRepo.new.for_select_pm_marks(where: where).map { |row| row[0] }.unshift('')
    end

    def for_select_packing_spec_pm_boms(where: {})
      MasterfilesApp::BomRepo.new.for_select_packing_spec_pm_boms(where: where).map { |row| row[0] }.unshift('')
    end

    def stepper(step_key)
      @stepper ||= PackingSpecificationWizardStepper.new(step_key, @user, @context.request_ip)
    end

    private

    def repo
      @repo ||= PackingSpecificationRepo.new
    end

    def validate_packing_specification_item_params(params)
      params[:fruit_sticker_ids] ||= []
      params[:tu_sticker_ids] ||= []
      params[:ru_sticker_ids] ||= []
      PackingSpecificationItemSchema.call(params)
    end
  end
end
