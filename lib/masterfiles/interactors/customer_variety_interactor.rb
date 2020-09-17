# frozen_string_literal: true

module MasterfilesApp
  class CustomerVarietyInteractor < BaseInteractor
    def create_customer_variety(params) # rubocop:disable Metrics/AbcSize
      marketing_variety_ids = Array(params[:customer_variety_varieties])
      return validation_failed_response(OpenStruct.new(messages: { marketing_variety_ids: ['You did not choose a marketing variety'] })) if marketing_variety_ids.empty?

      res = validate_customer_variety_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_customer_variety(res, marketing_variety_ids)
        log_status('customer_varieties', id, 'CREATED')
        log_transaction
      end
      instance = customer_variety(id)
      success_response("Created customer variety #{instance.id}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { id: ['This customer variety already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_customer_variety(id, params)
      res = validate_customer_variety_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_customer_variety(id, res)
        log_transaction
      end
      instance = customer_variety(id)
      success_response("Updated customer variety #{instance.id}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_customer_variety(id)
      name = customer_variety(id).id
      repo.transaction do
        repo.delete_customer_variety(id)
        log_status('customer_varieties', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted customer variety #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_customer_variety_variety(id)
      name = customer_variety_variety(id).id
      repo.transaction do
        repo.delete_customer_variety_variety(id)
        log_status('customer_variety_variety', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted customer variety variety #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::CustomerVariety.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def associate_customer_variety_varieties(id, marketing_variety_ids)
      return validation_failed_response(OpenStruct.new(messages: { marketing_variety_ids: ['You did not choose a marketing variety'] })) if marketing_variety_ids.empty?

      repo.transaction do
        repo.associate_customer_variety_varieties(id, marketing_variety_ids)
      end
      success_response('Customer Variety => Marketing Variety associated successfully')
    end

    def clone_customer_variety(id, packed_tm_group_ids)
      return validation_failed_response(OpenStruct.new(messages: { packed_tm_group_ids: ['You did not choose a packed tm group'] })) if packed_tm_group_ids.empty?

      repo.transaction do
        repo.clone_customer_variety(id, packed_tm_group_ids)
      end
      success_response('Customer Variety cloned successfully')
    end

    def for_select_group_marketing_varieties(variety_as_customer_variety_id)
      repo.for_select_group_marketing_varieties(variety_as_customer_variety_id)
    end

    private

    def repo
      @repo ||= MarketingRepo.new
    end

    def customer_variety(id)
      repo.find_customer_variety(id)
    end

    def customer_variety_variety(id)
      repo.find_customer_variety_variety(id)
    end

    def validate_customer_variety_params(params)
      CustomerVarietySchema.call(params)
    end
  end
end
