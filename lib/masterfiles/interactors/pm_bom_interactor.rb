# frozen_string_literal: true

module MasterfilesApp
  class PmBomInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_pm_bom(params) # rubocop:disable Metrics/AbcSize
      res = validate_pm_bom_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_pm_bom(res)
        log_status('pm_boms', id, 'CREATED')
        log_transaction
      end
      instance = pm_bom(id)
      success_response("Created pm bom #{instance.bom_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { bom_code: ['This pm bom already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_pm_bom(id, params)  # rubocop:disable Metrics/AbcSize
      system_code = repo.pm_bom_system_code(id)
      # params[:bom_code] = system_code
      res = validate_pm_bom_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_pm_bom(id, res.to_h.merge({ system_code: system_code }))
        log_transaction
      end
      instance = pm_bom(id)
      success_response("Updated pm bom #{instance.bom_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_pm_bom(id)
      name = pm_bom(id).bom_code
      repo.transaction do
        repo.delete_pm_bom(id)
        log_status('pm_boms', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted pm bom #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PmBom.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def select_subtypes(params)
      res = validate_select_subtypes(params)
      return validation_failed_response(res) if res.failure?

      res = validate_duplicate_types(res[:pm_subtype_ids])
      return validation_failed_response(res) unless res.success

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def multiselect_pm_products(multiselect_list, _pm_subtype_ids)  # rubocop:disable Metrics/AbcSize
      return failed_response('Pm Product selection cannot be empty') if multiselect_list.nil_or_empty?

      res = validate_duplicate_subtypes(pm_product_subtypes(multiselect_list))
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      pm_bom_id = nil
      repo.transaction do
        pm_bom_id = repo.create_pm_bom({ bom_code: 'TEST' })
        multiselect_list.each do |pm_product_id|
          repo.create(:pm_boms_products,
                      pm_product_id: pm_product_id,
                      pm_bom_id: pm_bom_id,
                      uom_id: find_uom_by_code(AppConst::DEFAULT_UOM_CODE),
                      quantity: 1)
        end
        system_code = repo.pm_bom_system_code(pm_bom_id)
        repo.update_pm_bom(pm_bom_id, { bom_code: system_code, system_code: system_code })
      end
      instance = pm_bom(pm_bom_id)
      success_response("Pm bom #{instance.system_code} created successfully",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      failed_response('This pm bom already exists')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def refresh_system_codes
      repo.transaction do
        repo.refresh_system_codes
      end

      success_response('Pm bom system codes were updated successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= BomsRepo.new
    end

    def pm_bom(id)
      repo.find_pm_bom(id)
    end

    def validate_pm_bom_params(params)
      PmBomSchema.call(params)
    end

    def validate_select_subtypes(params)
      PmBomSubtypeSchema.call(params)
    end

    def validate_duplicate_types(pm_subtype_ids)
      pm_type_ids = pm_subtype_types(pm_subtype_ids)
      duplicate_types = pm_type_ids.group_by { |a| a }.keep_if { |_, a| a.length > 1 }.keys
      return OpenStruct.new(success: false, messages: { pm_subtype_ids: ["Duplicate pm types: #{repo.pm_type_codes(duplicate_types).join(', ')}"] }, pm_subtype_ids: pm_subtype_ids) unless duplicate_types.nil_or_empty?

      OpenStruct.new(success: true, instance: { pm_subtype_ids: pm_subtype_ids })
    end

    def validate_duplicate_subtypes(pm_subtype_ids)
      duplicate_subtypes = pm_subtype_ids.group_by { |a| a }.keep_if { |_, a| a.length > 1 }.keys
      return failed_response("Duplicate pm types: #{repo.pm_subtype_codes(duplicate_subtypes).join(', ')}") unless duplicate_subtypes.nil_or_empty?

      ok_response
    end

    def pm_subtype_types(pm_subtype_ids)
      repo.pm_subtype_types(pm_subtype_ids)
    end

    def pm_product_subtypes(pm_product_ids)
      repo.pm_product_subtypes(pm_product_ids)
    end

    def find_uom_by_code(uom_code)
      repo.find_uom_by_code(uom_code)
    end
  end
end
