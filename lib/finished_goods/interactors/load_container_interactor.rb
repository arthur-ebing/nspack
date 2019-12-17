# frozen_string_literal: true

module FinishedGoodsApp
  class LoadContainerInteractor < BaseInteractor
    def create_load_container(params) # rubocop:disable Metrics/AbcSize
      res = validate_load_container_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_load_container(res)
        log_status(:load_containers, id, 'CREATED')
        log_transaction
      end
      instance = load_container(id)
      success_response("Created container #{instance.container_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { container_code: ['This container already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_load_container(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_load_container_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      # test for changes
      instance = load_container(id).to_h.reject { |k, _| %i[id active].include?(k) }
      return success_response("Load: #{instance[:load_id]}", instance) if instance == res.output

      # update date field if weight changed
      res.output[:verified_gross_weight_date] = Time.now if instance[:verified_gross_weight] != res.output[:verified_gross_weight]

      repo.transaction do
        repo.update_load_container(id, res)
        log_transaction
      end
      instance = load_container(id)
      success_response("Updated container #{instance.container_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_load_container(id)
      name = load_container(id).container_code
      repo.transaction do
        repo.delete_load_container(id)
        log_status(:load_containers, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted container #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::LoadContainer.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= LoadContainerRepo.new
    end

    def load_container(id)
      repo.find_load_container(id)
    end

    def validate_load_container_params(params)
      LoadContainerSchema.call(params)
    end
  end
end
