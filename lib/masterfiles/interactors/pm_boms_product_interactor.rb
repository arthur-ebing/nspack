# frozen_string_literal: true

module MasterfilesApp
  class PmBomsProductInteractor < BaseInteractor
    def create_pm_boms_product(params) # rubocop:disable Metrics/AbcSize
      res = validate_pm_boms_product_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_pm_boms_product(res)
        system_code = repo.pm_bom_system_code(res[:pm_bom_id])
        repo.update_pm_bom(res[:pm_bom_id], { bom_code: system_code, system_code: system_code })
        log_status(:pm_boms_products, id, 'CREATED')
        log_transaction
      end
      instance = pm_boms_product(id)
      success_response("Created PKG BOM product #{instance.id}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { uom_id: ['This PKG BOM product already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_pm_boms_product(id, params)  # rubocop:disable Metrics/AbcSize
      res = validate_pm_boms_product_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_pm_boms_product(id, res)
        system_code = repo.pm_bom_system_code(res[:pm_bom_id])
        repo.update_pm_bom(res[:pm_bom_id], { bom_code: system_code, system_code: system_code })
        log_transaction
      end
      instance = pm_boms_product(id)
      success_response("Updated PKG BOM product #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_pm_boms_product(id)  # rubocop:disable Metrics/AbcSize
      instance = pm_boms_product(id)
      name = instance.id
      pm_bom_id = instance.pm_bom_id

      repo.transaction do
        repo.delete_pm_boms_product(id)
        system_code = repo.pm_bom_system_code(pm_bom_id)
        repo.update_pm_bom(pm_bom_id, { bom_code: system_code, system_code: system_code })
        log_status(:pm_boms_products, id, 'DELETED')
        log_transaction
      end
      instance = pm_bom(pm_bom_id)
      success_response("Deleted PKG BOM product #{name}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PmBomsProduct.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def for_select_subtype_products(where: {})
      MasterfilesApp::BomRepo.new.for_select_pm_products(where: where)
    end

    def inline_edit_bom_product(bom_product_id, params)
      if params[:column_name] == 'uom_code'
        update_uom_code(bom_product_id, params)
      elsif params[:column_name] == 'quantity'
        update_quantity(bom_product_id, params)
      else
        failed_response(%(There is no handler for changed column "#{params[:column_name]}"))
      end
    end

    def update_uom_code(bom_product_id, params)
      res = repo.update_uom_code(bom_product_id, params[:column_value])
      res.instance = { refresh_bom_code: false, changes: { uom_id: res.instance[:uom_id] } }
      res
    end

    def update_quantity(bom_product_id, params)  # rubocop:disable Metrics/AbcSize
      pm_bom_id = DB[:pm_boms_products].where(id: bom_product_id).get(:pm_bom_id)

      res = nil
      repo.transaction do
        res = repo.update_quantity(bom_product_id, params[:column_value])
        system_code = repo.pm_bom_system_code(pm_bom_id)
        repo.update_pm_bom(pm_bom_id, { bom_code: system_code, system_code: system_code })
      end

      instance = pm_bom(pm_bom_id)
      res.instance = { refresh_bom_code: true,
                       bom_code: instance[:bom_code],
                       system_code: instance[:system_code],
                       changes: { quantity: res.instance[:quantity] } }
      res
    end

    private

    def repo
      @repo ||= BomRepo.new
    end

    def pm_boms_product(id)
      repo.find_pm_boms_product(id)
    end

    def pm_bom(id)
      repo.find_pm_bom(id)
    end

    def validate_pm_boms_product_params(params)
      PmBomsProductSchema.call(params)
    end
  end
end
