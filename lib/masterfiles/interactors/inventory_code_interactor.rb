# frozen_string_literal: true

module MasterfilesApp
  class InventoryCodeInteractor < BaseInteractor
    def create_inventory_code(params)
      res = validate_inventory_code_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_inventory_code(res)
        log_status('inventory_codes', id, 'CREATED')
        log_transaction
      end
      instance = inventory_code(id)
      success_response("Created inventory code #{instance.inventory_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { inventory_code: ['This inventory code already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_inventory_code(id, params)
      res = validate_inventory_code_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_inventory_code(id, res)
        log_transaction
      end
      instance = inventory_code(id)
      success_response("Updated inventory code #{instance.inventory_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_inventory_code(id)
      name = inventory_code(id).inventory_code
      repo.transaction do
        repo.delete_inventory_code(id)
        log_status('inventory_codes', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted inventory code #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::InventoryCode.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def sync_inventory_packing_costs(inventory_code_id)
      repo.transaction do
        repo.sync_inventory_packing_costs(inventory_code_id)
      end
      success_response('Inventory Packing Costs created successfully.')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def inline_update_packing_cost(id, params)
      res = validate_inline_update_packing_cost_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_inventory_codes_packing_cost(id, packing_cost: res[:column_value])
        log_transaction
      end

      instance = inventory_codes_packing_cost(id)
      success_response('Updated packing cost', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= FruitRepo.new
    end

    def inventory_code(id)
      repo.find_inventory_code(id)
    end

    def inventory_codes_packing_cost(id)
      repo.find_inventory_codes_packing_cost(id)
    end

    def validate_inventory_code_params(params)
      InventoryCodeSchema.call(params)
    end

    def validate_inline_update_packing_cost_params(params)
      PackingCostInlineUpdateSchema.call(params)
    end
  end
end
