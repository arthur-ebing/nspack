# frozen_string_literal: true

module MasterfilesApp
  class PucInteractor < BaseInteractor
    def create_puc(params) # rubocop:disable Metrics/AbcSize
      res = validate_puc_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_puc(res)
        # repo.create_farms_pucs(id,@puc_id)
        log_status('pucs', id, 'CREATED')
        log_transaction
      end
      instance = puc(id)
      success_response("Created puc #{instance.puc_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { puc_code: ['This puc already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_puc(id, params)
      res = validate_puc_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_puc(id, res)
        log_transaction
      end
      instance = puc(id)
      success_response("Updated puc #{instance.puc_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_puc(id)
      name = puc(id).puc_code
      repo.transaction do
        repo.delete_farms_pucs(id)
        repo.delete_puc(id)
        log_status('pucs', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted puc #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Puc.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= FarmRepo.new
    end

    def puc(id)
      repo.find_puc(id)
    end

    def validate_puc_params(params)
      PucSchema.call(params)
    end
  end
end
