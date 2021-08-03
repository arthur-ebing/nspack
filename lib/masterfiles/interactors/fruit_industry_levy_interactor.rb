# frozen_string_literal: true

module MasterfilesApp
  class FruitIndustryLevyInteractor < BaseInteractor
    def create_fruit_industry_levy(params)
      res = validate_fruit_industry_levy_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_fruit_industry_levy(res)
        log_status(:fruit_industry_levies, id, 'CREATED')
        log_transaction
      end
      instance = fruit_industry_levy(id)
      success_response("Created fruit industry levy #{instance.levy_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { levy_code: ['This fruit industry levy already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_fruit_industry_levy(id, params)
      res = validate_fruit_industry_levy_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_fruit_industry_levy(id, res)
        log_transaction
      end
      instance = fruit_industry_levy(id)
      success_response("Updated fruit industry levy #{instance.levy_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_fruit_industry_levy(id) # rubocop:disable Metrics/AbcSize
      name = fruit_industry_levy(id).levy_code
      repo.transaction do
        repo.delete_fruit_industry_levy(id)
        log_status(:fruit_industry_levies, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted fruit industry levy #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete fruit industry levy. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::FruitIndustryLevy.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= PartyRepo.new
    end

    def fruit_industry_levy(id)
      repo.find_fruit_industry_levy(id)
    end

    def validate_fruit_industry_levy_params(params)
      FruitIndustryLevySchema.call(params)
    end
  end
end
