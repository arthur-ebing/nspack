# frozen_string_literal: true

module MasterfilesApp
  class PortInteractor < BaseInteractor
    def create_port(params) # rubocop:disable Metrics/AbcSize
      res = validate_port_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_port(res.instance)
      end
      instance = port(id)
      success_response("Created port #{instance.port_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { port_code: ['This port already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_port(id, params)
      res = validate_port_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_port(id, res.instance)
      end
      instance = port(id)
      success_response("Updated port #{instance.port_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_port(id)
      name = port(id).port_code
      repo.transaction do
        repo.delete_port(id)
      end
      success_response("Deleted port #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Port.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= PortRepo.new
    end

    def port(id)
      repo.find_port_flat(id)
    end

    def validate_port_params(params)
      res = PortSchema.call(params)
      return res unless res.errors.empty?

      attrs = res.to_h
      %i[port_type_ids voyage_type_ids].each { |k| attrs[k] = Sequel.pg_array(attrs[k].map(&:to_i)) }
      OpenStruct.new(instance: attrs, messages: {})
    end
  end
end
