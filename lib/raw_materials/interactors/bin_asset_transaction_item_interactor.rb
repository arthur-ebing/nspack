# frozen_string_literal: true

module RawMaterialsApp
  class BinAssetTransactionItemInteractor < BaseInteractor
    def create_bin_asset_transaction_item(parent_id, params) # rubocop:disable Metrics/AbcSize
      params[:bin_asset_transaction_id] = parent_id
      res = validate_bin_asset_transaction_item_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_bin_asset_transaction_item(res)
        log_status(:bin_asset_transaction_items, id, 'CREATED')
        log_transaction
      end
      instance = bin_asset_transaction_item(id)
      success_response("Created bin asset transaction item #{instance.id}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { id: ['This bin asset transaction item already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_bin_asset_transaction_item(id, params)
      res = validate_bin_asset_transaction_item_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_bin_asset_transaction_item(id, res)
        log_transaction
      end
      instance = bin_asset_transaction_item(id)
      success_response("Updated bin asset transaction item #{instance.id}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_bin_asset_transaction_item(id)
      name = bin_asset_transaction_item(id).id
      repo.transaction do
        repo.delete_bin_asset_transaction_item(id)
        log_status(:bin_asset_transaction_items, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted bin asset transaction item #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::BinAssetTransactionItem.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= BinAssetsRepo.new
    end

    def bin_asset_transaction_item(id)
      repo.find_bin_asset_transaction_item(id)
    end

    def validate_bin_asset_transaction_item_params(params)
      BinAssetTransactionItemSchema.call(params)
    end
  end
end
