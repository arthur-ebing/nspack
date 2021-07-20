# frozen_string_literal: true

module MasterfilesApp
  class CultivarInteractor < BaseInteractor
    def create_cultivar(params)
      res = validate_cultivar_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_cultivar(res)
        log_status(:cultivars, id, 'CREATED')
        log_transaction
      end
      instance = cultivar(id)
      success_response("Created cultivar #{instance.cultivar_name}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { cultivar_name: ['This cultivar already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_cultivar(id, params)
      res = validate_cultivar_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_cultivar(id, res)
        log_transaction
      end
      instance = cultivar(id)
      success_response("Updated cultivar #{instance.cultivar_name}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_cultivar(id)
      name = cultivar(id).cultivar_name
      repo.transaction do
        repo.delete_cultivar(id)
        log_status(:cultivars, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted cultivar #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete cultivar. It is still referenced#{e.message.partition('referenced').last}")
    end

    def create_marketing_variety(cultivar_id, params)
      res = validate_marketing_variety_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_marketing_variety(cultivar_id, res)
        log_status(:marketing_varieties, id, 'CREATED')
        log_transaction
      end
      instance = marketing_variety(id)
      success_response("Created marketing variety #{instance.marketing_variety_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { marketing_variety_code: ['This marketing variety already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_marketing_variety(id, params)
      res = validate_marketing_variety_params(params)
      return validation_failed_response(res) if res.failure?

      repo.update_marketing_variety(id, res)
      instance = marketing_variety(id)
      success_response("Updated marketing variety #{instance.marketing_variety_code}", instance)
    end

    def delete_marketing_variety(id)
      name = marketing_variety(id).marketing_variety_code
      repo.delete_marketing_variety(id)
      success_response("Deleted marketing variety #{name}")
    end

    def link_marketing_varieties(cultivar_id, marketing_variety_ids)
      repo.transaction do
        repo.link_marketing_varieties(cultivar_id, marketing_variety_ids)
      end

      existing_ids = repo.cultivar_marketing_variety_ids(cultivar_id)
      if existing_ids.eql?(marketing_variety_ids.sort)
        success_response('Marketing varieties linked successfully')
      else
        failed_response('Some marketing varieties were not linked')
      end
    end

    private

    def repo
      @repo ||= CultivarRepo.new
    end

    def cultivar(id)
      repo.find_cultivar(id)
    end

    def validate_cultivar_params(params)
      CultivarSchema.call(params)
    end

    def marketing_variety(id)
      repo.find_marketing_variety(id)
    end

    def validate_marketing_variety_params(params)
      MarketingVarietySchema.call(params)
    end
  end
end
