# frozen_string_literal: true

module MasterfilesApp
  class StandardPackInteractor < BaseInteractor
    def create_standard_pack(params)
      res = validate_standard_pack_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_standard_pack(res)
        log_status(:standard_pack_codes, id, 'CREATED')
        log_transaction
      end
      instance = standard_pack(id)
      success_response("Created standard pack #{instance.standard_pack_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { standard_pack_code: ['This standard pack already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_standard_pack(id, params)
      res = validate_standard_pack_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_standard_pack(id, res)
        log_transaction
      end
      instance = standard_pack(id)
      success_response("Updated standard pack #{instance.standard_pack_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_standard_pack(id) # rubocop:disable Metrics/AbcSize
      name = standard_pack(id).standard_pack_code
      repo.transaction do
        repo.delete_standard_pack(id)
        log_status(:standard_pack_codes, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted standard pack #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete standard pack. It is still referenced#{e.message.partition('referenced').last}")
    end

    private

    def repo
      @repo ||= FruitSizeRepo.new
    end

    def standard_pack(id)
      repo.find_standard_pack(id)
    end

    def validate_standard_pack_params(params)
      StandardPackContract.new.call(params)
    end
  end
end
