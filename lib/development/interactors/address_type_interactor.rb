# frozen_string_literal: true

module DevelopmentApp
  class AddressTypeInteractor < BaseInteractor
    def create_address_type(params) # rubocop:disable Metrics/AbcSize
      res = validate_address_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_address_type(res)
        log_status(:address_types, id, 'CREATED')
        log_transaction
      end
      instance = find_address_type(id)
      success_response("Created address type #{instance.address_type}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { address_type: ['This address type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_address_type(id, params)
      res = validate_address_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_address_type(id, res)
        log_transaction
      end
      instance = find_address_type(id)
      success_response("Updated address type #{instance.address_type}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_address_type(id) # rubocop:disable Metrics/AbcSize
      name = find_address_type(id).address_type
      repo.transaction do
        repo.delete_address_type(id)
        log_status(:address_types, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted address type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete address type. It is still referenced#{e.message.partition('referenced').last}")
    end

    private

    def repo
      @repo ||= AddressTypeRepo.new
    end

    def find_address_type(id)
      repo.find_address_type(id)
    end

    def validate_address_type_params(params)
      AddressTypeSchema.call(params)
    end
  end
end
