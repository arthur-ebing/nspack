# frozen_string_literal: true

module RawMaterialsApp
  class EmptyBinTransactionItemInteractor < BaseInteractor
    def create_empty_bin_transaction_item(parent_id, params) # rubocop:disable Metrics/AbcSize
      params[:empty_bin_transaction_id] = parent_id
      res = validate_empty_bin_transaction_item_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_empty_bin_transaction_item(res)
        log_status(:empty_bin_transaction_items, id, 'CREATED')
        log_transaction
      end
      instance = empty_bin_transaction_item(id)
      success_response("Created empty bin transaction item #{instance.id}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { id: ['This empty bin transaction item already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_empty_bin_transaction_item(id, params)
      res = validate_empty_bin_transaction_item_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_empty_bin_transaction_item(id, res)
        log_transaction
      end
      instance = empty_bin_transaction_item(id)
      success_response("Updated empty bin transaction item #{instance.id}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_empty_bin_transaction_item(id)
      name = empty_bin_transaction_item(id).id
      repo.transaction do
        repo.delete_empty_bin_transaction_item(id)
        log_status(:empty_bin_transaction_items, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted empty bin transaction item #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::EmptyBinTransactionItem.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= EmptyBinsRepo.new
    end

    def empty_bin_transaction_item(id)
      repo.find_empty_bin_transaction_item(id)
    end

    def validate_empty_bin_transaction_item_params(params)
      EmptyBinTransactionItemSchema.call(params)
    end
  end
end
