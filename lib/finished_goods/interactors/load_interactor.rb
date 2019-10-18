# frozen_string_literal: true

module FinishedGoodsApp
  class LoadInteractor < BaseInteractor
    def create_load(params) # rubocop:disable Metrics/AbcSize
      res = validate_load_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_load(res)
        log_status('loads', id, 'CREATED')
        log_transaction
      end
      instance = load(id)
      success_response("Created load #{instance.order_number}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { order_number: ['This load already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_load(id, params)
      res = validate_load_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_load(id, res)
        log_transaction
      end
      instance = load(id)
      success_response("Updated load #{instance.order_number}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_load(id)
      name = load(id).order_number
      repo.transaction do
        repo.delete_load(id)
        log_status('loads', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted load #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Load.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= LoadRepo.new
    end

    def load(id)
      repo.find_load(id)
    end

    def validate_load_params(params)
      LoadSchema.call(params)
    end
  end
end
