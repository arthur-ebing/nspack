# frozen_string_literal: true

module MasterfilesApp
  class AdvancedClassificationsInteractor < BaseInteractor
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

    def delete_ripeness_code(id)
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

    def delete_rmt_handling_regime(id)
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

    def assert_handling_regime_permission!(task, id = nil)
      res = TaskPermissionCheck::RmtHandlingRegime.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def assert_ripeness_code_permission!(task, id = nil)
      res = TaskPermissionCheck::RipenessCode.call(task, id)
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

    def validate_rmt_handling_regime_params(params)
      RmtHandlingRegimeSchema.call(params)
    end
  end
end
