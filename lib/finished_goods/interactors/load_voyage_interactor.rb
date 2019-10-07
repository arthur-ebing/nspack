# frozen_string_literal: true

module FinishedGoodsApp
  class LoadVoyageInteractor < BaseInteractor
    def create_load_voyage(params) # rubocop:disable Metrics/AbcSize
      res = validate_load_voyage_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_load_voyage(res)
        log_status('load_voyages', id, 'CREATED')
        log_transaction
      end
      instance = load_voyage(id)
      success_response("Created load voyage #{instance.booking_reference}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { booking_reference: ['This load voyage already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_load_voyage(id, params)
      res = validate_load_voyage_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_load_voyage(id, res)
        log_transaction
      end
      instance = load_voyage(id)
      success_response("Updated load voyage #{instance.booking_reference}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_load_voyage(id)
      name = load_voyage(id).booking_reference
      repo.transaction do
        repo.delete_load_voyage(id)
        log_status('load_voyages', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted load voyage #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::LoadVoyage.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= LoadVoyageRepo.new
    end

    def load_voyage(id)
      repo.find_load_voyage(id)
    end

    def validate_load_voyage_params(params)
      LoadVoyageSchema.call(params)
    end
  end
end
