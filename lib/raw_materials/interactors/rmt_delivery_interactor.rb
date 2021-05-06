# frozen_string_literal: true

module RawMaterialsApp
  class RmtDeliveryInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_rmt_delivery(params) # rubocop:disable Metrics/AbcSize
      res = validate_rmt_delivery_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_rmt_delivery(res)
        log_status(:rmt_deliveries, id, 'DELIVERY_RECEIVED')
        log_transaction
      end
      instance = rmt_delivery(id)
      success_response("Created RMT delivery #{id}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { reference_number: ['This RMT delivery already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_rmt_delivery(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_rmt_delivery_params(params)
      return failed_response(unwrap_failed_response(validation_failed_response(res))) if res.failure? && res.errors.to_h.one? && res.errors.to_h.include?(:season_id)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_rmt_delivery(id, res)
        log_transaction
      end
      instance = rmt_delivery(id)
      success_response("Updated RMT delivery #{instance.reference_number}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_rmt_delivery(id) # rubocop:disable Metrics/AbcSize
      tipped_bins = repo.find_delivery_tipped_bins(id)
      return failed_response("#{tipped_bins.length} have already been tipped") unless tipped_bins.empty?

      repo.transaction do
        bins = repo.find_bins_by_delivery_id(id)
        unless bins.empty?
          delivery = repo.delivery_confirmation_details(id)
          before = { farm: delivery[:farm_code], puc: delivery[:puc_code], orchard: delivery[:orchard_code], cultivar_group: delivery[:cultivar_group_code],
                     cultivar: delivery[:cultivar_name], date_picked: delivery[:date_picked], date_delivered: delivery[:date_delivered], delivery_id: id }
          after = { farm: nil, puc: nil, orchard: nil, cultivar_group: nil, cultivar: nil, date_picked: nil, date_delivered: nil, delivery_id: nil }
          reworks_run_attrs = { user: @user.user_name, reworks_run_type_id: ProductionApp::ReworksRepo.new.get_reworks_run_type_id(AppConst::RUN_TYPE_DELIVERY_DELETE), pallets_selected: bins.map { |b| b[:bin_asset_number] },
                                pallets_affected: bins.map { |b| b[:bin_asset_number] }, allow_cultivar_group_mixing: nil }

          res = validate_reworks_run_params(reworks_run_attrs)
          return failed_response(unwrap_failed_response(validation_failed_response(res))) if res.failure?

          create_delete_rmt_delivery_reworks_run(res, before: before, after: after)
          repo.delete_rmt_bin(bins.map { |b| b[:id] })
        end

        repo.delete_rmt_delivery(id)
        log_status(:rmt_deliveries, id, 'DELETED')
        log_transaction
      end
      success_response('Deleted RMT delivery')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_delete_rmt_delivery_reworks_run(params, changes_made)
      ProductionApp::ReworksRepo.new.create_reworks_run(user: params[:user],
                                                        reworks_run_type_id: params[:reworks_run_type_id],
                                                        scrap_reason_id: nil,
                                                        remarks: nil,
                                                        pallets_selected: "{ #{params[:pallets_selected].join(',')} }",
                                                        pallets_affected: "{ #{params[:pallets_affected].join(',')} }",
                                                        changes_made: { pallets: { pallet_sequences: { changes: changes_made } } }.to_json)
    end

    def update_received_at(id, params) # rubocop:disable Metrics/AbcSize
      res = RmtDeliveryReceivedAtSchema.call(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update(:rmt_deliveries, id, res.to_h)
        log_status(:rmt_deliveries, id, AppConst::RMT_BIN_RECEIPT_DATE_OVERRIDE)

        bin_ids = repo.select_values(:rmt_bins, :id, rmt_delivery_id: id)
        repo.update(:rmt_bins, bin_ids, bin_received_date_time: params[:date_delivered])
        log_multiple_statuses(:rmt_bins, bin_ids, AppConst::RMT_BIN_RECEIPT_DATE_OVERRIDE)
        log_transaction
      end
      instance = rmt_delivery(id)
      success_response("Updated RMT delivery #{instance.reference_number}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def validate_batch_number(batch_number)
      return validation_failed_response(OpenStruct.new(messages: { batch_number: ['Must be filled'] })) if batch_number.empty?
      return validation_failed_response(OpenStruct.new(messages: { batch_number: ['Batch already exists'] })) if repo.exists?(:rmt_deliveries, batch_number: batch_number)

      ok_response
    end

    def create_delivery_batch(batch_number, ids)
      repo.transaction do
        repo.update_rmt_delivery(ids, batch_number: batch_number, batch_number_updated_at: Time.now)
      end
      success_response("Batch #{batch_number} created successfully")
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def manage_delivery_batch(rep_delivery_id, selection) # rubocop:disable Metrics/AbcSize
      rep_delivery_batch = repo.get_value(:rmt_deliveries, :batch_number, id: rep_delivery_id)
      current_batch = repo.select_values(:rmt_deliveries, :id, batch_number: rep_delivery_batch)
      repo.transaction do
        repo.update_rmt_delivery(selection - current_batch, batch_number: rep_delivery_batch, batch_number_updated_at: Time.now)
        repo.update_rmt_delivery(current_batch - selection, batch_number: nil, batch_number_updated_at: Time.now)
      end
      success_response("Batch #{rep_delivery_batch} updated successfully")
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delivery_set_current(id)
      repo.transaction do
        repo.delivery_set_current(id)
      end
      success_response("Delivery #{id} set as current")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def keep_delivery_open(id)
      repo.transaction do
        repo.update_rmt_delivery(id, keep_open: true, delivery_tipped: false)
        log_status(:rmt_deliveries, id, 'DELIVERY OPENED')
        log_transaction
      end
      instance = rmt_delivery(id)

      success_response('Delivery: Has Been Opened', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def receive_delivery(id)
      repo.transaction do
        repo.update_rmt_delivery(id, date_delivered: Time.now, received: true)
        log_status(:rmt_deliveries, id, 'DELIVERY_RECEIVED')
        log_transaction
      end
      instance = rmt_delivery(id)

      success_response('Delivery: Has Been Received', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def reopen_delivery(id)
      repo.transaction do
        repo.update_rmt_delivery(id, delivery_tipped: false)
        log_status(:rmt_deliveries, id, 'DELIVERY REOPENED')
        log_transaction
      end
      instance = rmt_delivery(id)

      success_response('Delivery: Has Been Reopened', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def close_delivery(id)
      changeset = { keep_open: false }
      changeset[:delivery_tipped] = true if repo.all_bins_tipped?(id)

      repo.transaction do
        repo.update_rmt_delivery(id, changeset)
        log_status(:rmt_deliveries, id, 'DELIVERY CLOSED')
        log_transaction
      end
      instance = rmt_delivery(id)
      return failed_response('Delivery: Could Not Be Closed', instance) if instance.keep_open

      success_response('Delivery: Has Been Closed', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def recalc_rmt_bin_nett_weight(id) # rubocop:disable Metrics/AbcSize
      repo.transaction do
        rmt_bins = repo.find_bins_by_delivery_id(id)
        rmt_bins.each do |rmt_bin|
          tare_weight = repo.get_rmt_bin_tare_weight(rmt_bin)

          if !rmt_bin[:bin_tipped] && rmt_bin[:gross_weight] && tare_weight
            # override nett_weight
            repo.update_rmt_bin(rmt_bin[:id], nett_weight: (rmt_bin[:gross_weight] - tare_weight))
          end
        end
      end
      success_response('Bin nett weight calculated successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_cost_type(params) # rubocop:disable Metrics/AbcSize
      res = validate_cost_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_cost_type(res)
        log_status(:cost_types, id, 'CREATED')
        log_transaction
      end
      instance = cost_type(id)
      success_response("Created cost type #{instance.cost_type_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { cost_type_code: ['This cost type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_cost_type(id, params)
      res = validate_cost_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_cost_type(id, res)
        log_transaction
      end
      instance = cost_type(id)
      success_response("Updated cost type #{instance.cost_type_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_cost_type(id) # rubocop:disable Metrics/AbcSize
      name = cost_type(id).cost_type_code
      repo.transaction do
        repo.delete_cost_type(id)
        log_status(:cost_types, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted cost type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete cost type. It is still referenced#{e.message.partition('referenced').last}")
    end

    def create_cost(params) # rubocop:disable Metrics/AbcSize
      res = validate_cost_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_cost(res)
        log_status(:costs, id, 'CREATED')
        log_transaction
      end
      instance = cost(id)
      success_response("Created cost #{instance.id}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { id: ['This cost already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_cost(id, params)
      res = validate_cost_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_cost(id, res)
        log_transaction
      end
      instance = cost(id)
      success_response("Updated cost #{instance.id}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_cost(id) # rubocop:disable Metrics/AbcSize
      name = cost(id).id
      repo.transaction do
        repo.delete_cost(id)
        log_status(:costs, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted cost #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete cost. It is still referenced#{e.message.partition('referenced').last}")
    end

    def lookup_farms_pucs(farm_id)
      repo.farm_pucs(farm_id)
    end

    def lookup_orchards(farm_id, puc_id)
      repo.orchards(farm_id, puc_id)
    end

    def lookup_orchard_cultivars(orchard_id)
      repo.orchard_cultivars(orchard_id)
    end

    def find_cultivar_by_delivery(delivery_id)
      repo.cultivar_by_delivery_id(delivery_id)
    end

    def find_orchard_by_delivery(delivery_id)
      repo.orchard_by_delivery_id(delivery_id)
    end

    def find_rmt_container_type_by_container_type_code(container_type_code)
      repo.rmt_container_type_by_container_type_code(container_type_code)
    end

    def delivery_tipped?(id)
      repo.get(:rmt_deliveries, id, :delivery_tipped)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::RmtDelivery.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def create_rmt_delivery_cost(id, params) # rubocop:disable Metrics/AbcSize
      params[:rmt_delivery_id] = id
      res = validate_rmt_delivery_cost_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.create_rmt_delivery_cost(res)
        log_transaction
      end
      instance = rmt_delivery_cost(id, res[:cost_id])
      success_response("Created RMT delivery cost #{instance[:id]}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { base: ['This RMT delivery cost already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_rmt_delivery_cost(rmt_delivery_id, cost_id, params)
      params[:rmt_delivery_id] = rmt_delivery_id
      res = validate_rmt_delivery_cost_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_rmt_delivery_cost(rmt_delivery_id, cost_id, res)
        log_transaction
      end
      instance = rmt_delivery_cost(rmt_delivery_id, cost_id)
      success_response('Updated RMT delivery cost', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_rmt_delivery_cost(rmt_delivery_id, cost_id)
      repo.transaction do
        repo.delete_rmt_delivery_cost(rmt_delivery_id, cost_id)
        log_transaction
      end
      success_response('Deleted RMT delivery cost')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete RMT delivery cost. It is still referenced#{e.message.partition('referenced').last}")
    end

    def cost(id)
      repo.find_cost_flat(id)
    end

    private

    def rmt_delivery_cost(rmt_delivery_id, cost_id)
      repo.find_rmt_delivery_cost_flat(rmt_delivery_id, cost_id)
    end

    def validate_rmt_delivery_cost_params(params)
      RmtDeliveryCostSchema.call(params)
    end

    def repo
      @repo ||= RmtDeliveryRepo.new
    end

    def rmt_delivery(id)
      repo.find_rmt_delivery(id)
    end

    def validate_rmt_delivery_params(params)
      RmtDeliverySchema.call(params)
    end

    def validate_reworks_run_params(params)
      ProductionApp::ReworksRunFlatSchema.call(params)
    end

    def cost_type(id)
      repo.find_cost_type(id)
    end

    def validate_cost_type_params(params)
      MasterfilesApp::CostTypeSchema.call(params)
    end

    def validate_cost_params(params)
      MasterfilesApp::CostSchema.call(params)
    end
  end
end
