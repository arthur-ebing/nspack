# frozen_string_literal: true

module FinishedGoodsApp
  class VoyageInteractor < BaseInteractor
    def create_voyage(params) # rubocop:disable Metrics/AbcSize
      res = validate_voyage_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_voyage(res)
        log_status('voyages', id, 'CREATED')
        log_transaction
      end
      instance = voyage(id)
      success_response("Created voyage #{instance.voyage_number}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { voyage_number: ['This voyage already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_voyage(id, params)
      res = validate_voyage_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_voyage(id, res)
        log_transaction
      end
      instance = voyage(id)
      success_response("Updated voyage #{instance.voyage_number}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_voyage(id)
      name = voyage(id).voyage_number
      repo.transaction do
        repo.delete_voyage(id)
        log_status('voyages', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted voyage #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def complete_a_voyage(id, params)
      res = complete_a_record(:voyages, id, params.merge(enqueue_job: false))
      if res.success
        success_response(res.message, voyage(id))
      else
        failed_response(res.message, voyage(id))
      end
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Voyage.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= VoyageRepo.new
    end

    def voyage(id)
      repo.find_voyage_flat(id)
    end

    def validate_voyage_params(params)
      VoyageSchema.call(params)
    end
  end
end
