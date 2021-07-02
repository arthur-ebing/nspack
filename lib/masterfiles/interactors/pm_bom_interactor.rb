# frozen_string_literal: true

module MasterfilesApp
  class PmBomInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_pm_bom(params)
      res = validate_pm_bom_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_pm_bom(res)
        log_status(:pm_boms, id, 'CREATED')
        log_transaction
      end
      instance = pm_bom(id)
      success_response("Created PKG BOM #{instance.bom_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { bom_code: ['This PKG BOM already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_pm_bom(id, params) # rubocop:disable Metrics/AbcSize
      system_code = repo.pm_bom_system_code(id)
      params[:bom_code] = system_code
      attrs = params.merge(system_code: system_code)
      res = validate_pm_bom_params(attrs)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_pm_bom(id, res)
        log_transaction
      end
      instance = pm_bom(id)
      success_response("Updated PKG BOM #{instance.bom_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_pm_bom(id)
      name = pm_bom(id).bom_code
      repo.transaction do
        repo.delete_pm_bom(id)
        log_status(:pm_boms, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted PKG BOM #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PmBom.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def select_pm_types(params)
      res = validate_pm_types_params(params)
      return validation_failed_response(res) if res.failure?

      instance = repo.select_values(:pm_subtypes, :id, pm_type_id: res[:pm_type_ids])
      success_response('ok', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def multiselect_pm_products(multiselect_list) # rubocop:disable Metrics/AbcSize
      res = validate_multiselect_pm_products(multiselect_list)
      return failed_response(unwrap_failed_response(res)) unless res.success

      pm_bom_id = nil
      repo.transaction do
        pm_bom_id = repo.create_pm_bom({ bom_code: 'TEST' })
        uom_id = repo.get_id(:uoms, uom_code: AppConst::DEFAULT_UOM_CODE)
        multiselect_list.each do |pm_product_id|
          repo.create(:pm_boms_products,
                      pm_product_id: pm_product_id,
                      pm_bom_id: pm_bom_id,
                      uom_id: uom_id,
                      quantity: 1)
        end
        system_code = repo.pm_bom_system_code(pm_bom_id)
        repo.update_pm_bom(pm_bom_id, { bom_code: system_code, system_code: system_code })
      end
      instance = pm_bom(pm_bom_id)
      success_response("PKG BOM #{instance.system_code} created successfully", instance)
    rescue Sequel::UniqueConstraintViolation
      failed_response('This PKG BOM already exists')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def refresh_system_codes
      repo.transaction do
        pm_bom_ids = repo.select_values(:pm_boms, :id)
        pm_bom_ids.each do |id|
          system_code = repo.pm_bom_system_code(id)
          repo.update_pm_bom(id, bom_code: system_code, system_code: system_code)
        end
      end

      success_response('PKG BOM system codes were updated successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def calculate_bom_weights(id)
      repo.transaction do
        repo.calculate_bom_weights(id)
      end

      instance = pm_bom(id)
      success_response('BOM weights updated successfully', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def resolve_pm_bom_clone_attrs(pm_bom_id)
      instance = repo.resolve_pm_bom_clone_attrs(pm_bom_id)
      success_response('ok', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def clone_bom_to_counts(bom_attrs, fruit_count_product_ids)
      return failed_response('Fruit count product selection cannot be empty') if fruit_count_product_ids.nil_or_empty?

      repo.transaction do
        fruit_count_product_ids.each do |fruit_count_product_id|
          repo.clone_bom_to_count(bom_attrs, fruit_count_product_id)
        end
      end
      success_response('PKG Bom cloned successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= BomRepo.new
    end

    def pm_bom(id)
      repo.find_pm_bom(id)
    end

    def validate_pm_bom_params(params)
      PmBomSchema.call(params)
    end

    def validate_pm_types_params(params)
      PmBomTypeSchema.call(params)
    end

    def validate_multiselect_pm_products(multiselect_list) # rubocop:disable Metrics/AbcSize
      return failed_response('PKG Product selection cannot be empty') if multiselect_list.nil_or_empty?

      pm_subtype_ids = repo.select_values(:pm_products, :pm_subtype_id, id: multiselect_list)

      pm_type_ids = repo.select_values(:pm_subtypes, :pm_type_id, id: pm_subtype_ids)
      duplicate_types = pm_type_ids.group_by { |a| a }.keep_if { |_, a| a.length > 1 }.keys
      pm_type_codes = repo.select_values(:pm_types, :pm_type_code, id: duplicate_types)
      return failed_response("Duplicate PKG Types: #{pm_type_codes.join(', ')}") unless duplicate_types.nil_or_empty?

      duplicate_subtypes = pm_subtype_ids.group_by { |a| a }.keep_if { |_, a| a.length > 1 }.keys
      pm_subtype_codes = repo.select_values(:pm_subtypes, :subtype_code, id: duplicate_subtypes)
      return failed_response("Duplicate PKG Subtypes: #{pm_subtype_codes.join(', ')}") unless duplicate_subtypes.nil_or_empty?

      ok_response
    end
  end
end
