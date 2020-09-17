# frozen_string_literal: true

module MasterfilesApp
  class FruitSizeReferenceInteractor < BaseInteractor
    def create_fruit_size_reference(params) # rubocop:disable Metrics/AbcSize
      res = validate_fruit_size_reference_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_fruit_size_reference(res)
        log_status('fruit_size_references', id, 'CREATED')
        log_transaction
      end
      instance = fruit_size_reference(id)
      success_response("Created fruit size reference #{instance.size_reference}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { size_reference: ['This fruit size reference already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_fruit_size_reference(id, params)
      res = validate_fruit_size_reference_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_fruit_size_reference(id, res)
        log_transaction
      end
      instance = fruit_size_reference(id)
      success_response("Updated fruit size reference #{instance.size_reference}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_fruit_size_reference(id)
      name = fruit_size_reference(id).size_reference
      repo.transaction do
        repo.delete_fruit_size_reference(id)
        log_status('fruit_size_references', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted fruit size reference #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::FruitSizeReference.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= FruitSizeRepo.new
    end

    def fruit_size_reference(id)
      repo.find_fruit_size_reference(id)
    end

    def validate_fruit_size_reference_params(params)
      FruitSizeReferenceSchema.call(params)
    end
  end
end
