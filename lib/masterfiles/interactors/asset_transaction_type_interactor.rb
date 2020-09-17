# frozen_string_literal: true

module MasterfilesApp
  class AssetTransactionTypeInteractor < BaseInteractor
    def create_asset_transaction_type(params) # rubocop:disable Metrics/AbcSize
      res = validate_asset_transaction_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_asset_transaction_type(res)
        log_status(:asset_transaction_types, id, 'CREATED')
        log_transaction
      end
      instance = asset_transaction_type(id)
      success_response("Created asset transaction type #{instance.transaction_type_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { transaction_type_code: ['This asset transaction type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_asset_transaction_type(id, params)
      res = validate_asset_transaction_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_asset_transaction_type(id, res)
        log_transaction
      end
      instance = asset_transaction_type(id)
      success_response("Updated asset transaction type #{instance.transaction_type_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_asset_transaction_type(id)
      name = asset_transaction_type(id).transaction_type_code
      repo.transaction do
        repo.delete_asset_transaction_type(id)
        log_status(:asset_transaction_types, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted asset transaction type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    # def complete_a_asset_transaction_type(id, params)
    #   res = complete_a_record(:asset_transaction_types, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, asset_transaction_type(id))
    #   else
    #     failed_response(res.message, asset_transaction_type(id))
    #   end
    # end

    # def reopen_a_asset_transaction_type(id, params)
    #   res = reopen_a_record(:asset_transaction_types, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, asset_transaction_type(id))
    #   else
    #     failed_response(res.message, asset_transaction_type(id))
    #   end
    # end

    # def approve_or_reject_a_asset_transaction_type(id, params)
    #   res = if params[:approve_action] == 'a'
    #           approve_a_record(:asset_transaction_types, id, params.merge(enqueue_job: false))
    #         else
    #           reject_a_record(:asset_transaction_types, id, params.merge(enqueue_job: false))
    #         end
    #   if res.success
    #     success_response(res.message, asset_transaction_type(id))
    #   else
    #     failed_response(res.message, asset_transaction_type(id))
    #   end
    # end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::AssetTransactionType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= AssetTransactionTypeRepo.new
    end

    def asset_transaction_type(id)
      repo.find_asset_transaction_type(id)
    end

    def validate_asset_transaction_type_params(params)
      AssetTransactionTypeSchema.call(params)
    end
  end
end
