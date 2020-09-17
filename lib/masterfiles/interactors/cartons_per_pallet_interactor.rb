# frozen_string_literal: true

module MasterfilesApp
  class CartonsPerPalletInteractor < BaseInteractor
    def create_cartons_per_pallet(params) # rubocop:disable Metrics/AbcSize
      res = validate_cartons_per_pallet_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_cartons_per_pallet(res)
        log_status('cartons_per_pallet', id, 'CREATED')
        log_transaction
      end
      instance = cartons_per_pallet(id)
      success_response("Created cartons per pallet #{instance.description}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { description: ['This cartons per pallet already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_cartons_per_pallet(id, params)
      res = validate_cartons_per_pallet_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_cartons_per_pallet(id, res)
        log_transaction
      end
      instance = cartons_per_pallet(id)
      success_response("Updated cartons per pallet #{instance.description}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_cartons_per_pallet(id)
      name = cartons_per_pallet(id).description
      repo.transaction do
        repo.delete_cartons_per_pallet(id)
        log_status('cartons_per_pallet', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted cartons per pallet #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::CartonsPerPallet.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= PackagingRepo.new
    end

    def cartons_per_pallet(id)
      repo.find_cartons_per_pallet(id)
    end

    def validate_cartons_per_pallet_params(params)
      CartonsPerPalletSchema.call(params)
    end
  end
end
