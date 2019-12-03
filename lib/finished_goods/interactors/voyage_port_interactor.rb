# frozen_string_literal: true

module FinishedGoodsApp
  class VoyagePortInteractor < BaseInteractor
    def create_voyage_port(voyage_id, params) # rubocop:disable Metrics/AbcSize
      res = validate_voyage_port_params(params.merge(voyage_id: voyage_id))
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_voyage_port(res)
        log_status(:voyage_ports, id, 'CREATED')
        log_transaction
      end
      instance = voyage_port(id)
      success_response("Created voyage port #{instance.id}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { port_id: ['Port already in voyage'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_voyage_port(id, params)
      res = validate_voyage_port_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_voyage_port(id, res)
        log_transaction
      end
      instance = voyage_port(id)
      success_response("Updated voyage port #{instance.id}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_voyage_port(id)
      name = voyage_port(id).id
      repo.transaction do
        repo.delete_voyage_port(id)
        log_status(:voyage_ports, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted voyage port #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::VoyagePort.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= VoyagePortRepo.new
    end

    def voyage_port(id)
      repo.find_voyage_port_flat(id)
    end

    def validate_voyage_port_params(params)
      VoyagePortSchema.call(params)
    end
  end
end
