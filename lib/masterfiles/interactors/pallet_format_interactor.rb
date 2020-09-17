# frozen_string_literal: true

module MasterfilesApp
  class PalletFormatInteractor < BaseInteractor
    def create_pallet_format(params) # rubocop:disable Metrics/AbcSize
      res = validate_pallet_format_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_pallet_format(res)
        log_status('pallet_formats', id, 'CREATED')
        log_transaction
      end
      instance = pallet_format(id)
      success_response("Created pallet format #{instance.description}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { description: ['This pallet format already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_pallet_format(id, params)
      res = validate_pallet_format_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_pallet_format(id, res)
        log_transaction
      end
      instance = pallet_format(id)
      success_response("Updated pallet format #{instance.description}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_pallet_format(id)
      name = pallet_format(id).description
      repo.transaction do
        repo.delete_pallet_format(id)
        log_status('pallet_formats', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted pallet format #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PalletFormat.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= PackagingRepo.new
    end

    def pallet_format(id)
      repo.find_pallet_format(id)
    end

    def validate_pallet_format_params(params)
      PalletFormatSchema.call(params)
    end
  end
end
