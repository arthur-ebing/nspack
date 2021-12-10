# frozen_string_literal: true

module MasterfilesApp
  class AdvancedClassificationsInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_ripeness_code(params)
      res = validate_ripeness_code_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_ripeness_code(res)
        log_status(:ripeness_codes, id, 'CREATED')
        log_transaction
      end
      instance = ripeness_code(id)
      success_response("Created ripeness code #{instance.ripeness_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { ripeness_code: ['This ripeness code already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_ripeness_code(id, params)
      res = validate_ripeness_code_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_ripeness_code(id, res)
        log_transaction
      end
      instance = ripeness_code(id)
      success_response("Updated ripeness code #{instance.ripeness_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_ripeness_code(id) # rubocop:disable Metrics/AbcSize
      name = ripeness_code(id).ripeness_code
      repo.transaction do
        repo.delete_ripeness_code(id)
        log_status(:ripeness_codes, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted ripeness code #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete ripeness code. It is still referenced#{e.message.partition('referenced').last}")
    end

    def create_rmt_handling_regime(params)
      res = validate_rmt_handling_regime_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_rmt_handling_regime(res)
        log_status(:rmt_handling_regimes, id, 'CREATED')
        log_transaction
      end
      instance = rmt_handling_regime(id)
      success_response("Created rmt handling regime #{instance.regime_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { regime_code: ['This rmt handling regime already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_rmt_handling_regime(id, params)
      res = validate_rmt_handling_regime_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_rmt_handling_regime(id, res)
        log_transaction
      end
      instance = rmt_handling_regime(id)
      success_response("Updated rmt handling regime #{instance.regime_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_rmt_handling_regime(id) # rubocop:disable Metrics/AbcSize
      name = rmt_handling_regime(id).regime_code
      repo.transaction do
        repo.delete_rmt_handling_regime(id)
        log_status(:rmt_handling_regimes, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted rmt handling regime #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete rmt handling regime. It is still referenced#{e.message.partition('referenced').last}")
    end

    def create_rmt_variant(cultivar_id, params) # rubocop:disable Metrics/AbcSize
      params[:cultivar_id] = cultivar_id
      res = validate_rmt_variant_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      add_grid_row = repo.exists?(:rmt_variants, cultivar_id: cultivar_id)
      repo.transaction do
        id = repo.create_rmt_variant(res)
        log_status(:rmt_variants, id, 'CREATED')
        log_transaction
      end
      instance = rmt_code_grid_row_by_cultivar_and_variant(cultivar_id, id)
      success_response("Created rmt variant: #{instance[:rmt_variant_code]} for cultivar: #{instance[:cultivar_name]}", add_grid_row: add_grid_row, rmt_variant: instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { rmt_variant_code: ['This rmt variant already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_rmt_variant(id, params)
      res = validate_rmt_variant_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_rmt_variant(id, res)
        log_transaction
      end
      instance = rmt_variant(id)
      success_response("Updated rmt variant: #{instance.rmt_variant_code} for cultivar: #{instance.cultivar_name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_rmt_variant(id) # rubocop:disable Metrics/AbcSize
      res = TaskPermissionCheck::RmtVariant.call(:delete, id)
      raise failed_response(res.message) unless res.success

      instance = rmt_variant(id)
      repo.transaction do
        repo.delete_rmt_variant(id)
        log_status(:rmt_variants, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted rmt variant: #{instance.rmt_variant_code} for cultivar: #{instance.cultivar_name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete rmt variant. It is still referenced#{e.message.partition('referenced').last}")
    end

    def create_rmt_code(rmt_variant_id, params) # rubocop:disable Metrics/AbcSize
      params[:rmt_variant_id] = rmt_variant_id
      res = validate_rmt_code_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      add_grid_row = repo.exists?(:rmt_codes, rmt_variant_id: rmt_variant_id)
      repo.transaction do
        id = repo.create_rmt_code(res)
        log_status(:rmt_codes, id, 'CREATED')
        log_transaction
      end
      instance = rmt_code_grid_row_by_rmt_code_id(id)
      success_response("Created rmt code #{instance[:rmt_code]}", add_grid_row: add_grid_row, rmt_code: instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { rmt_code: ['This rmt code already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_rmt_code(id, params)
      params[:rmt_variant_id] = repo.get(:rmt_codes, id, :rmt_variant_id)
      res = validate_rmt_code_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_rmt_code(id, res)
        log_transaction
      end
      instance = rmt_code_grid_row_by_rmt_code_id(id)
      success_response("Updated rmt code #{instance[:rmt_code]}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_rmt_code(id) # rubocop:disable Metrics/AbcSize
      res = TaskPermissionCheck::RmtCode.call(:delete, id)
      raise failed_response(res.message) unless res.success

      name = repo.get(:rmt_codes, id, :rmt_code)
      repo.transaction do
        repo.delete_rmt_code(id)
        log_status(:rmt_codes, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted rmt code #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete rmt code. It is still referenced#{e.message.partition('referenced').last}")
    end

    def create_rmt_classification_type(params)
      res = validate_rmt_classification_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_rmt_classification_type(res)
        log_status(:rmt_classification_types, id, 'CREATED')
        log_transaction
      end
      instance = rmt_classifications_grid_row_by_type_id(id)
      success_response("Created rmt classification type #{instance[:rmt_classification_type_code]}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { rmt_classification_type_code: ['This rmt classification type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_rmt_classification_type(id, params)
      res = validate_rmt_classification_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_rmt_classification_type(id, res)
        log_transaction
      end
      instance = rmt_classifications_grid_row_by_type_id(id)
      success_response("Updated rmt classification type #{instance[:rmt_classification_type_code]}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_rmt_classification_type(id) # rubocop:disable Metrics/AbcSize
      res = TaskPermissionCheck::RmtClassificationType.call(:delete, id)
      raise failed_response(res.message) unless res.success

      name = rmt_classification_type(id).rmt_classification_type_code
      repo.transaction do
        repo.delete_rmt_classification_type(id)
        log_status(:rmt_classification_types, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted rmt classification type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete rmt classification type. It is still referenced#{e.message.partition('referenced').last}")
    end

    def create_rmt_classification(rmt_classification_type_id, params) # rubocop:disable Metrics/AbcSize
      params[:rmt_classification_type_id] = rmt_classification_type_id
      res = validate_rmt_classification_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      add_grid_row = repo.exists?(:rmt_classifications, rmt_classification_type_id: rmt_classification_type_id)
      repo.transaction do
        id = repo.create_rmt_classification(res)
        log_status(:rmt_classifications, id, 'CREATED')
        log_transaction
      end
      instance = rmt_classifications_grid_row_by_classification_id(id)
      success_response("Created rmt classification #{instance[:rmt_classification]}", add_grid_row: add_grid_row, rmt_classification: instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { rmt_classification: ['This rmt classification already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_rmt_classification(id, params)
      params[:rmt_classification_type_id] = repo.get_value(:rmt_classifications, :rmt_classification_type_id, id: id)
      res = validate_rmt_classification_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_rmt_classification(id, res)
        log_transaction
      end
      instance = rmt_classifications_grid_row_by_classification_id(id)
      success_response("Updated rmt classification #{instance[:rmt_classification]}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_rmt_classification(id) # rubocop:disable Metrics/AbcSize
      res = TaskPermissionCheck::RmtClassification.call(:delete, id)
      raise failed_response(res.message) unless res.success

      name = repo.get_value(:rmt_classifications, :rmt_classification, id: id)
      repo.transaction do
        repo.delete_rmt_classification(id)
        log_status(:rmt_classifications, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted rmt classification #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete rmt classification. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_rmt_classification_permission!(task, id = nil)
      res = TaskPermissionCheck::RmtClassification.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def assert_rmt_classification_type_permission!(task, id = nil)
      res = TaskPermissionCheck::RmtClassificationType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def assert_handling_regime_permission!(task, id = nil)
      res = TaskPermissionCheck::RmtHandlingRegime.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def assert_ripeness_code_permission!(task, id = nil)
      res = TaskPermissionCheck::RipenessCode.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def assert_rmt_variant_permission!(task, id = nil)
      res = TaskPermissionCheck::RmtVariant.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def assert_rmt_code_permission!(task, id = nil)
      res = TaskPermissionCheck::RmtCode.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= AdvancedClassificationsRepo.new
    end

    def ripeness_code(id)
      repo.find_ripeness_code_flat(id)
    end

    def validate_ripeness_code_params(params)
      RipenessCodeSchema.call(params)
    end

    def rmt_handling_regime(id)
      repo.find_rmt_handling_regime_flat(id)
    end

    def rmt_code_grid_row_by_cultivar_and_variant(cultivar_id, id)
      repo.rmt_code_grid_row(" where cultivars.id=#{cultivar_id} and rmt_variants.id=#{id}")
    end

    def rmt_code_grid_row_by_rmt_code_id(id)
      repo.rmt_code_grid_row(" where rmt_codes.id=#{id}")
    end

    def rmt_classifications_grid_row_by_type_id(id)
      repo.rmt_classifications_grid_row(" where rmt_classification_types.id=#{id}")
    end

    def rmt_classifications_grid_row_by_classification_id(id)
      repo.rmt_classifications_grid_row(" where rmt_classifications.id=#{id}")
    end

    def rmt_variant(id)
      repo.find_rmt_variant_flat(id)
    end

    def rmt_classification(id)
      repo.find_rmt_classification(id)
    end

    def rmt_classification_type(id)
      repo.find_rmt_classification_type(id)
    end

    def validate_rmt_classification_type_params(params)
      RmtClassificationTypeSchema.call(params)
    end

    def validate_rmt_classification_params(params)
      RmtClassificationSchema.call(params)
    end

    def validate_rmt_variant_params(params)
      RmtVariantSchema.call(params)
    end

    def validate_rmt_handling_regime_params(params)
      RmtHandlingRegimeSchema.call(params)
    end

    def validate_rmt_code_params(params)
      RmtCodeSchema.call(params)
    end
  end
end
