# frozen_string_literal: true

module MasterfilesApp
  class CustomerInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_customer(params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      res = CreateCustomerSchema.call(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        res = if res[:rmt_customer]
                CreatePartyRole.call(AppConst::ROLE_RMT_CUSTOMER, params, @user, column_name: :customer_party_role_id)
              else
                CreatePartyRole.call(AppConst::ROLE_CUSTOMER, params, @user)
              end
        raise Crossbeams::ServiceError unless res.success

        params[:customer_party_role_id] = res.instance.party_role_id
        res = CustomerSchema.call(params)
        raise Crossbeams::ServiceError if res.failure?

        id = repo.create_customer(res)
        create_bin_asset_trading_partner_location(id, res) if create_trading_partner_location?(res)
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

    def update_customer(id, params) # rubocop:disable Metrics/AbcSize
      instance = customer(id)
      res = validate_customer_params(params.merge(rmt_customer: instance.rmt_customer))
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_customer(id, res)
        log_transaction
      end
      create_or_destroy_trading_partner_location(id, res) if AppConst::CR_RMT.create_bin_asset_trading_partner_location?
      instance = customer(id)
      success_response("Updated customer #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_customer(id) # rubocop:disable Metrics/AbcSize
      name = customer(id).customer
      location_id = customer_location_id(id)
      repo.transaction do
        repo.delete_customer(id)
        log_status(:customers, id, 'DELETED')
        log_transaction
      end
      delete_bin_asset_trading_partner_location(location_id) if AppConst::CR_RMT.create_bin_asset_trading_partner_location?
      success_response("Deleted customer #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete customer. It is still referenced#{e.message.partition('referenced').last}")
    end

    def delete_bin_asset_trading_partner_location(location_id)
      location_repo.delete_location(location_id)
      ok_response
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Customer.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= FinanceRepo.new
    end

    def location_repo
      @location_repo ||= LocationRepo.new
    end

    def party_repo
      @party_repo ||= MasterfilesApp::PartyRepo.new
    end

    def customer(id)
      repo.find_customer(id)
    end

    def validate_customer_params(params)
      CustomerSchema.call(params)
    end

    def create_trading_partner_location?(params)
      # NOTE: This is set to true IF
      # AppConst::CR_RMT.create_bin_asset_trading_partner_location? rule is set AND
      # Customer is an RMT CUSTOMER AND bin_asset_trading_partner is true.
      create = AppConst::CR_RMT.create_bin_asset_trading_partner_location?
      create = false unless params[:rmt_customer]
      create = false unless params[:bin_asset_trading_partner]
      create
    end

    def create_bin_asset_trading_partner_location(customer_id, attrs)
      customer_code = party_repo.fn_party_role_name(attrs[:customer_party_role_id])
      location_id = repo.get_id_or_create(:locations, resolve_location_attrs_for(customer_code))
      repo.update(:customers, customer_id, location_id: location_id)
    end

    def create_or_destroy_trading_partner_location(customer_id, attrs)
      return create_bin_asset_trading_partner_location(customer_id, attrs) if create_trading_partner_location?(attrs)

      return unless attrs[:rmt_customer]

      location_id = customer_location_id(customer_id)
      return if location_id.nil?

      repo.update(:customers, customer_id, location_id: nil)
      delete_bin_asset_trading_partner_location(location_id)
    end

    def resolve_location_attrs_for(customer_code)
      { primary_storage_type_id: repo.get_id(:location_storage_types, storage_type_code: AppConst::STORAGE_TYPE_BIN_ASSET),
        location_type_id: repo.get_id(:location_types, location_type_code: AppConst::LOCATION_TYPES_BIN_ASSET_TRADING_PARTNER),
        primary_assignment_id: repo.get_id(:location_assignments, assignment_code: AppConst::EMPTY_BIN_STORAGE),
        location_long_code: customer_code,
        location_description: customer_code,
        location_short_code: customer_code }
    end

    def customer_location_id(customer_id)
      repo.get(:customers, customer_id, :location_id)
    end
  end
end
