# frozen_string_literal: true

module FinishedGoodsApp
  class PalletHoldoverInteractor < BaseInteractor
    def create_pallet_holdover(params)
      res = validate_pallet_holdover_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_pallet_holdover(res)
        log_status(:pallet_holdovers, id, 'CREATED')
        log_transaction
      end
      instance = pallet_holdover(id)
      success_response("Created pallet holdover #{instance.buildup_remarks}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { buildup_remarks: ['This pallet holdover already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_pallet_holdover(id, params)
      res = validate_pallet_holdover_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_pallet_holdover(id, res)
        log_transaction
      end
      instance = pallet_holdover(id)
      success_response("Updated pallet holdover #{instance.buildup_remarks}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_pallet_holdover(id)
      name = pallet_holdover(id).buildup_remarks
      repo.transaction do
        repo.delete_pallet_holdover(id)
        log_status(:pallet_holdovers, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted pallet holdover #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete pallet holdover. It is still referenced#{e.message.partition('referenced').last}")
    end

    def complete_a_pallet_holdover(id, params)
      res = complete_a_record(:pallet_holdovers, id, params)
      if res.success
        success_response(res.message, pallet_holdover(id))
      else
        failed_response(res.message, pallet_holdover(id))
      end
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PalletHoldover.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= PalletHoldoverRepo.new
    end

    def pallet_holdover(id)
      repo.find_pallet_holdover(id)
    end

    def validate_pallet_holdover_params(params)
      PalletHoldoverSchema.call(params)
    end
  end
end
