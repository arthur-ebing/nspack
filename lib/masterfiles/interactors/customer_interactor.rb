# frozen_string_literal: true

module MasterfilesApp
  class CustomerInteractor < BaseInteractor
    def create_customer(params) # rubocop:disable Metrics/AbcSize
      res = CreateCustomerSchema.call(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        res = CreatePartyRole.call(AppConst::ROLE_CUSTOMER, params, @user)
        raise Crossbeams::ServiceError unless res.success

        params[:customer_party_role_id] = res.instance.party_role_id
        res = CustomerSchema.call(params)
        raise Crossbeams::ServiceError if res.failure?

        id = repo.create_customer(res)
        log_status(:customers, id, 'CREATED')
        log_transaction
      end
      instance = customer(id)
      success_response("Created customer #{instance.customer}", instance)
    rescue Sequel::UniqueConstraintViolation => e
      key = e.to_s.partition('(').last.partition(')').first
      validation_failed_response(OpenStruct.new(messages: { key.to_sym => ["This #{key.gsub('_', ' ')} already exists"] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Crossbeams::ServiceError
      res
    end

    def update_customer(id, params)
      res = validate_customer_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_customer(id, res)
        log_transaction
      end
      instance = customer(id)
      success_response("Updated customer #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_customer(id)
      name = customer(id).customer
      repo.transaction do
        repo.delete_customer(id)
        log_status(:customers, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted customer #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete customer. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Customer.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= FinanceRepo.new
    end

    def customer(id)
      repo.find_customer(id)
    end

    def validate_customer_params(params)
      CustomerSchema.call(params)
    end
  end
end
