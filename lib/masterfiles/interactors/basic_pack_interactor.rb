# frozen_string_literal: true

module MasterfilesApp
  class BasicPackInteractor < BaseInteractor
    def create_basic_pack(params)
      res = validate_basic_pack_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_basic_pack(res)
        log_status(:basic_pack_codes, id, 'CREATED')
        log_transaction
      end
      instance = basic_pack(id)
      success_response("Created basic pack #{instance.basic_pack_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { basic_pack_code: ['This basic pack already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_basic_pack(id, params)
      res = validate_basic_pack_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_basic_pack(id, res)
        log_transaction
      end
      instance = basic_pack(id)
      success_response("Updated basic pack #{instance.basic_pack_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_basic_pack(id)
      name = basic_pack(id).basic_pack_code
      repo.transaction do
        repo.delete_basic_pack(id)
        log_status(:basic_pack_codes, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted basic pack #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete basic pack. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::BasicPack.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= FruitSizeRepo.new
    end

    def basic_pack(id)
      repo.find_basic_pack(id)
    end

    def validate_basic_pack_params(params)
      BasicPackSchema.call(params)
    end
  end
end
