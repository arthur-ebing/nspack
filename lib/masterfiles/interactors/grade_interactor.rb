# frozen_string_literal: true

module MasterfilesApp
  class GradeInteractor < BaseInteractor
    def create_grade(params) # rubocop:disable Metrics/AbcSize
      res = validate_grade_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_grade(res)
        log_status('grades', id, 'CREATED')
        log_transaction
      end
      instance = grade(id)
      success_response("Created grade #{instance.grade_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { grade_code: ['This grade already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_grade(id, params)
      res = validate_grade_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_grade(id, res)
        log_transaction
      end
      instance = grade(id)
      success_response("Updated grade #{instance.grade_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_grade(id)
      name = grade(id).grade_code
      repo.transaction do
        repo.delete_grade(id)
        log_status('grades', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted grade #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Grade.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= FruitRepo.new
    end

    def grade(id)
      repo.find_grade(id)
    end

    def validate_grade_params(params)
      GradeSchema.call(params)
    end
  end
end
