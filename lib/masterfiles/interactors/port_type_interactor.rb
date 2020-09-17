# frozen_string_literal: true

module MasterfilesApp
  class PortTypeInteractor < BaseInteractor
    def create_port_type(params) # rubocop:disable Metrics/AbcSize
      res = validate_port_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_port_type(res)
        log_transaction
      end
      instance = port_type(id)
      success_response("Created port type #{instance.port_type_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { port_type_code: ['This port type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_port_type(id, params)
      res = validate_port_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_port_type(id, res)
        log_transaction
      end
      instance = port_type(id)
      success_response("Updated port type #{instance.port_type_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_port_type(id)
      name = port_type(id).port_type_code
      repo.transaction do
        repo.delete_port_type(id)
        log_transaction
      end
      success_response("Deleted port type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PortType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= PortTypeRepo.new
    end

    def port_type(id)
      repo.find_port_type(id)
    end

    def validate_port_type_params(params)
      PortTypeSchema.call(params)
    end
  end
end
