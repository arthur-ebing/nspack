# frozen_string_literal: true

module ProductionApp
  class PackingSpecificationItemInteractor < BaseInteractor
    def create_packing_specification_item(params) # rubocop:disable Metrics/AbcSize
      res = validate_packing_specification_item_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_packing_specification_item(res)
        log_status(:packing_specification_items, id, 'CREATED')
        log_transaction
      end
      instance = packing_specification_item(id)
      success_response("Created packing specification item #{instance.description}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { description: ['This packing specification item already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_packing_specification_item(id, params)
      res = validate_packing_specification_item_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_packing_specification_item(id, res)
        log_transaction
      end
      instance = packing_specification_item(id)
      success_response("Updated packing specification item #{instance.description}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_packing_specification_item(id) # rubocop:disable Metrics/AbcSize
      name = packing_specification_item(id).description
      repo.transaction do
        repo.delete_packing_specification_item(id)
        log_status(:packing_specification_items, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted packing specification item #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete packing specification item. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PackingSpecificationItem.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= PackingSpecificationRepo.new
    end

    def packing_specification_item(id)
      repo.find_packing_specification_item(id)
    end

    def validate_packing_specification_item_params(params)
      params[:fruit_sticker_ids] ||= []
      params[:tu_sticker_ids] ||= []
      params[:ru_sticker_ids] ||= []
      PackingSpecificationItemSchema.call(params)
    end
  end
end
