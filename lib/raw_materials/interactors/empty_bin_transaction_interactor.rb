# frozen_string_literal: true

module RawMaterialsApp
  class EmptyBinTransactionInteractor < BaseInteractor
    def create_empty_bin_transaction # rubocop:disable Metrics/AbcSize
      res = validate_stepper
      return res unless res.success

      @parent_transaction_id = nil
      repo.transaction do # rubocop:disable Metrics/BlockLength
        res.instance[:bin_sets].each do |set|
          owner_id = repo.get_id(:rmt_container_material_owners,
                                 rmt_material_owner_party_role_id: set[:rmt_container_material_owner_id],
                                 rmt_container_material_type_id: set[:rmt_container_material_type_id])
          opts = {
            asset_transaction_type_id: res.instance[:asset_transaction_type_id],
            parent_transaction_id: @parent_transaction_id,
            business_process_id: res.instance[:business_process_id],
            ref_no: res.instance[:reference_number],
            fruit_reception_delivery_id: res.instance[:fruit_reception_delivery_id],
            truck_registration_number: res.instance[:truck_registration_number],
            quantity_bins: res.instance[:quantity_bins].to_i,
            is_adhoc: false,
            user_name: @user.user_name
          }
          empty_bin_move_response = RawMaterialsApp::MoveEmptyBins.call(
            owner_id,
            set[:quantity_bins].to_i,
            res.instance[:empty_bin_to_location_id],
            res.instance[:empty_bin_from_location_id],
            opts
          )
          raise Crossbeams::InfoError, empty_bin_move_response.message unless empty_bin_move_response.success

          transaction_item_id = empty_bin_move_response.instance
          @parent_transaction_id = empty_bin_transaction_item(transaction_item_id)&.empty_bin_transaction_id
        end
      end
      log_status(:empty_bin_transactions, @parent_transaction_id, 'CREATED')
      log_transaction
      instance = empty_bin_transaction(@parent_transaction_id)
      success_response("Created empty bin transaction #{instance.truck_registration_number}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { truck_registration_number: ['This empty bin transaction already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::EmptyBinTransaction.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def truck_registration_number(delivery_id)
      repo.truck_registration_number_for_delivery(delivery_id)
    end

    def stepper
      @stepper ||= EmptyBinControlStep.new(@user, @context.request_ip, repo)
    end

    def rmt_container_material_types(owner_party_role_id)
      repo.options_for_rmt_container_material_types(owner_party_role_id)
    end

    def validate_receive_params(params)
      res = ReceiveEmptyBinSchema.call(params)
      res.messages.empty? ? ok_response : validation_failed_response(res)
    end

    def validate_issue_params(params)
      res = IssueEmptyBinSchema.call(params)
      res.messages.empty? ? ok_response : validation_failed_response(res)
    end

    def validate_adhoc_params(params)
      res = AdhocEmptyBinSchema.call(params)
      res.messages.empty? ? ok_response : validation_failed_response(res)
    end

    def validate_stepper # rubocop:disable Metrics/AbcSize
      hash = stepper.read
      unless hash[:bin_sets].nil_or_empty?
        res = repo.validate_empty_bin_location_quantities(hash[:empty_bin_from_location_id], hash[:bin_sets])
        return res unless res.success
      end

      qty = hash[:quantity_bins].to_i
      return success_response('ok', hash) if qty == (total_qty = stepper.bin_sets.map { |set| set[:quantity_bins].to_i }.sum)

      x = qty - total_qty
      message = "Quantity Bins do not equate to total bins added. Please #{x.positive? ? 'add' : 'remove'} #{x.abs} bins."
      validation_failed_response(OpenStruct.new(messages: { base: [message] }, instance: hash))
    end

    def get_applicable_transaction_item_ids(location_id)
      repo.get_applicable_transaction_item_ids(location_id)
    end

    private

    def repo
      @repo ||= EmptyBinsRepo.new
    end

    def empty_bin_transaction(id)
      repo.find_empty_bin_transaction(id)
    end

    def empty_bin_transaction_item(item_id)
      repo.find_empty_bin_transaction_item(item_id)
    end
  end
end
