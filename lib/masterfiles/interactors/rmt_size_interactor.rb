# frozen_string_literal: true

module MasterfilesApp
  class RmtSizeInteractor < BaseInteractor
    def create_rmt_size(params) # rubocop:disable Metrics/AbcSize
      res = validate_rmt_size_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_rmt_size(res)
        log_status(:rmt_sizes, id, 'CREATED')
        log_transaction
      end
      instance = rmt_size(id)
      success_response("Created RMT size #{instance.size_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { size_code: ['This RMT size already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_rmt_size(id, params)
      res = validate_rmt_size_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_rmt_size(id, res)
        log_transaction
      end
      instance = rmt_size(id)
      success_response("Updated RMT size #{instance.size_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_rmt_size(id) # rubocop:disable Metrics/AbcSize
      name = rmt_size(id).size_code
      repo.transaction do
        repo.delete_rmt_size(id)
        log_status(:rmt_sizes, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted RMT size #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete RMT size. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::RmtSize.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= RmtSizeRepo.new
    end

    def rmt_size(id)
      repo.find_rmt_size(id)
    end

    def validate_rmt_size_params(params)
      RmtSizeSchema.call(params)
    end
  end
end
