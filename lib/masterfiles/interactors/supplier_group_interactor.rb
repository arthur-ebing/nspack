# frozen_string_literal: true

module MasterfilesApp
  class SupplierGroupInteractor < BaseInteractor
    def create_supplier_group(params) # rubocop:disable Metrics/AbcSize
      res = validate_supplier_group_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_supplier_group(res)
        log_status(:supplier_groups, id, 'CREATED')
        log_transaction
      end
      instance = supplier_group(id)
      success_response("Created supplier group #{instance.supplier_group_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { supplier_group_code: ['This supplier group already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_supplier_group(id, params)
      res = validate_supplier_group_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_supplier_group(id, res)
        log_transaction
      end
      instance = supplier_group(id)
      success_response("Updated supplier group #{instance.supplier_group_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_supplier_group(id) # rubocop:disable Metrics/AbcSize
      name = supplier_group(id).supplier_group_code
      repo.transaction do
        repo.delete_supplier_group(id)
        log_status(:supplier_groups, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted supplier group #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete supplier group. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::SupplierGroup.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= SupplierRepo.new
    end

    def supplier_group(id)
      repo.find_supplier_group(id)
    end

    def validate_supplier_group_params(params)
      SupplierGroupSchema.call(params)
    end
  end
end
