# frozen_string_literal: true

module MasterfilesApp
  class SupplierInteractor < BaseInteractor
    def create_supplier(params) # rubocop:disable Metrics/AbcSize
      unless params[:supplier_party_role_id].to_i.positive?
        res = CreatePartyRole.call(params[:supplier_party_role_id], AppConst::ROLE_SUPPLIER, params, @user)
        return res unless res.success

        params[:supplier_party_role_id] = res.instance
      end

      res = validate_supplier_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_supplier(res)
        log_status(:suppliers, id, 'CREATED')
        log_transaction
      end
      instance = supplier(id)
      success_response("Created supplier #{instance.supplier}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { id: ['This supplier already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_supplier(id, params)
      res = validate_supplier_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_supplier(id, res)
        log_transaction
      end
      instance = supplier(id)
      success_response("Updated supplier #{instance.supplier}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_supplier(id) # rubocop:disable Metrics/AbcSize
      name = supplier(id).supplier
      repo.transaction do
        repo.delete_supplier(id)
        log_status(:suppliers, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted supplier #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete supplier. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Supplier.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= SupplierRepo.new
    end

    def supplier(id)
      repo.find_supplier(id)
    end

    def validate_supplier_params(params)
      SupplierSchema.call(params)
    end
  end
end
