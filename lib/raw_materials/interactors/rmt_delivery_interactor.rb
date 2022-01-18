# frozen_string_literal: true

module RawMaterialsApp
  class RmtDeliveryInteractor < BaseInteractor
    def classify_raw_material(id, params) # rubocop:disable Metrics/AbcSize
      params[:rmt_classifications] = params.find_all { |k, _v| k != :rmt_code_id }.map { |a| a[1] }.reject(&:blank?)
      res = ClassifyRawMaterialContract.new.call(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_rmt_delivery(id, res)
        bin_ids = repo.select_values(:rmt_bins, :id, rmt_delivery_id: id)
        if res[:rmt_code_id]
          repo.update_rmt_bin(bin_ids, rmt_code_id: res[:rmt_code_id])
          log_status(:rmt_deliveries, id, AppConst::DELIVERY_RMT_CODE_ALLOCATED)
          log_multiple_statuses(:rmt_bins, bin_ids, AppConst::DELIVERY_RMT_CODE_ALLOCATED)
        end

        unless res[:rmt_classifications].empty?
          repo.update_rmt_bin(bin_ids, rmt_classifications: res[:rmt_classifications])
          log_status(:rmt_deliveries, id, AppConst::DELIVERY_RMT_CLASSIFICATIONS_ADDED)
          log_multiple_statuses(:rmt_bins, bin_ids, AppConst::DELIVERY_RMT_CLASSIFICATIONS_ADDED)
        end

        log_transaction
      end
      success_response("Delivery: #{id} has been classified successfully")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def create_delivery_tripsheet(delivery_id, params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      stock_type_id = MesscadaApp::MesscadaRepo.new.get_value(:stock_types, :id, stock_type_code: AppConst::BIN_STOCK_TYPE)
      params.merge!(business_process_id: repo.get_value(:business_processes, :id, process: AppConst::DELIVERY_TRIPSHEET_BUSINESS_PROCESS),
                    stock_type_id: stock_type_id, rmt_delivery_id: delivery_id)
      res = validate_tripsheet_params(params)
      return validation_failed_response(res) if res.failure?

      error_bins = []
      repo.transaction do
        vehicle_job_id = insp_repo.create_vehicle_job(res)
        bins = repo.select_values(:rmt_bins, :id, rmt_delivery_id: delivery_id)
        bins.each do |bin_id|
          if insp_repo.vehicle_job_unit_in_different_tripsheet?(bin_id, vehicle_job_id, AppConst::BIN_STOCK_TYPE)
            error_bins << bin_id
          else
            res = validate_vehicle_job_unit_params(stock_item_id: bin_id, stock_type_id: stock_type_id,
                                                   vehicle_job_id: vehicle_job_id)
            raise Crossbeams::InfoError, unwrap_failed_response(validation_failed_response(res)) if res.failure?

            insp_repo.create_vehicle_job_unit(res)
            log_status(:rmt_bins, bin_id, AppConst::RMT_BIN_ADDED_TO_DELIVERY_TRIPSHEET)
          end
        end

        raise Crossbeams::InfoError, 'Tripsheet Not Created: All bins belongs to other tripsheets' if bins.size == error_bins.size

        repo.update_rmt_delivery(delivery_id, tripsheet_created: true, tripsheet_created_at: Time.now)
        log_status(:rmt_deliveries, delivery_id, AppConst::DELIVERY_TRIPSHEET_CREATED)
        log_transaction
      end
      success_response("Tripsheet Created #{!error_bins.empty? ? ". Following bins on other tripsheets: #{error_bins.join(',')}" : nil}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def refresh_delivery_tripheet(id) # rubocop:disable Metrics/AbcSize
      tripheet_discreps = repo.delivery_tripsheet_discreps(id)
      unless tripheet_discreps.empty?
        repo.transaction do
          vehicle_loaded = repo.get_value(:rmt_deliveries, :tripsheet_loaded, id: id)
          vehicle_job_id = repo.get_id(:vehicle_jobs, rmt_delivery_id: id)
          stock_type_id = MesscadaApp::MesscadaRepo.new.get_value(:stock_types, :id, stock_type_code: AppConst::BIN_STOCK_TYPE)
          to_remove = tripheet_discreps.find_all { |d| !d[:bin_id] }.map { |v| v[:vehicle_job_unit_id] }
          insp_repo.delete(:vehicle_job_units, to_remove) unless to_remove.empty?
          tripheet_discreps.find_all { |d| !d[:vehicle_job_unit_id] }.map { |v| v[:bin_id] }.each do |b|
            res = validate_vehicle_job_unit_params(stock_item_id: b, stock_type_id: stock_type_id,
                                                   vehicle_job_id: vehicle_job_id)
            raise Crossbeams::InfoError, unwrap_failed_response(validation_failed_response(res)) if res.failure?

            insp_repo.create_vehicle_job_unit(res)
            log_status(:rmt_bins, b, AppConst::RMT_BIN_ADDED_TO_DELIVERY_TRIPSHEET)
            log_status(:rmt_bins, b, AppConst::RMT_BIN_LOADED_ON_VEHICLE) if vehicle_loaded
          end
          log_status(:rmt_deliveries, id, AppConst::DELIVERY_TRIPSHEET_REFRESHED)
          log_transaction
        end
      end
      success_response('Delivery Tripsheet Rereshed')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def cancel_delivery_tripheet(id) # rubocop:disable Metrics/AbcSize
      offloaded_bins = insp_repo.offloaded_delivery_bins_size(id)
      return failed_response("Couldn't cancel tripsheet: #{offloaded_bins} bins have already been offloaded") unless offloaded_bins.zero?

      repo.transaction do
        vehicle_job_id = repo.get_id(:vehicle_jobs, rmt_delivery_id: id)
        stock_type_id = repo.get_id(:stock_types, stock_type_code: AppConst::BIN_STOCK_TYPE)
        bins = repo.select_values(:vehicle_job_units, :stock_item_id, stock_type_id: stock_type_id, vehicle_job_id: vehicle_job_id)
        repo.update(:rmt_deliveries, id, tripsheet_created: false, tripsheet_created_at: nil, tripsheet_loaded: false, tripsheet_loaded_at: nil)
        insp_repo.delete_vehicle_job(vehicle_job_id)
        log_multiple_statuses(:rmt_bins, bins, AppConst::DELIVERY_TRIPSHEET_CANCELED)
        log_status(:rmt_deliveries, id, AppConst::DELIVERY_TRIPSHEET_CANCELED)
      end

      success_response 'Tripsheet deleted successfully'
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def start_bins_trip(id) # rubocop:disable Metrics/AbcSize
      repo.transaction do
        vehicle_job_id = repo.get_value(:vehicle_jobs, :id, rmt_delivery_id: id)
        repo.update(:rmt_deliveries, id, tripsheet_loaded: true, tripsheet_loaded_at: Time.now)
        repo.update(:vehicle_jobs, vehicle_job_id, loaded_at: Time.now)
        insp_repo.load_vehicle_job_units(vehicle_job_id)

        log_status(:rmt_deliveries, id, AppConst::RMT_BIN_LOADED_ON_VEHICLE)
        stock_type_id = repo.get_id(:stock_types, stock_type_code: AppConst::BIN_STOCK_TYPE)
        log_multiple_statuses(:rmt_bins, repo.select_values(:vehicle_job_units, :stock_item_id, stock_type_id: stock_type_id, vehicle_job_id: vehicle_job_id), AppConst::RMT_BIN_LOADED_ON_VEHICLE)
      end

      success_response('Vehicle Loaded')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def generate_sample_bin_sequences(sample_size, quantity_bins_with_fruit)
      (1..quantity_bins_with_fruit).to_a.sample(sample_size)
    end

    def get_delivery_sample_bins(cultivar_id, quantity_bins_with_fruit)
      return nil if AppConst::CR_RMT.sample_rmt_bin_percentage.zero?
      return nil unless repo.allocate_sample_rmt_bins_for_commodity_cultivar?(cultivar_id)

      sample_size = (AppConst::CR_RMT.sample_rmt_bin_percentage * quantity_bins_with_fruit).round
      sample_size = 1 if sample_size.zero?
      generate_sample_bin_sequences(sample_size, quantity_bins_with_fruit)
    end

    def create_rmt_delivery(params) # rubocop:disable Metrics/AbcSize
      res = validate_rmt_delivery_params(params)
      return validation_failed_response(res) if res.failure?

      sample_bins = get_delivery_sample_bins(res[:cultivar_id], res[:quantity_bins_with_fruit])
      sample_hash = sample_bins.nil_or_empty? ? {} : { sample_bins: sample_bins }

      id = nil
      repo.transaction do
        id = repo.create_rmt_delivery(res.to_h.merge(sample_hash))
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

    def update_rmt_delivery(id, params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      res = validate_rmt_delivery_params(params)
      return failed_response(unwrap_failed_response(validation_failed_response(res))) if res.failure? && res.errors.to_h.one? && res.errors.to_h.include?(:season_id)
      return validation_failed_response(res) if res.failure?

      bins_exist = repo.exists?(:rmt_bins, rmt_delivery_id: id)
      quantity_bins_with_fruit_changed = repo.get_value(:rmt_deliveries, :quantity_bins_with_fruit, id: id) != res[:quantity_bins_with_fruit]
      sample_hash = {}
      if !bins_exist && quantity_bins_with_fruit_changed
        sample_bins = get_delivery_sample_bins(res[:cultivar_id], res[:quantity_bins_with_fruit])
        sample_hash = sample_bins.nil_or_empty? ? {} : { sample_bins: sample_bins }
      end

      repo.transaction do
        repo.update_rmt_delivery(id, res.to_h.merge(sample_hash))
        if AppConst::CR_RMT.all_delivery_bins_of_same_type?
          bin_ids = repo.select_values(:rmt_bins, :id, rmt_delivery_id: id)
          attrs = { rmt_container_type_id: res[:rmt_container_type_id],
                    rmt_material_owner_party_role_id: res[:rmt_material_owner_party_role_id],
                    rmt_container_material_type_id: res[:rmt_container_material_type_id] }
          repo.update(:rmt_bins, bin_ids, attrs)
        end
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
      return failed_response('There is a completed QC Sample for this delivery') if repo.delivery_has_complete_qc_sample?(id)

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

        repo.delete_rmt_delivery_samples(id)
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

    def update_reference_number(id, params)
      repo.transaction do
        repo.update(:rmt_deliveries, id, params)
        log_status(:rmt_deliveries, id, AppConst::RMT_BIN_REFERENCE_NUMBER_OVERRIDE)
        log_transaction
      end
      instance = rmt_delivery(id)
      success_response("Updated RMT delivery #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
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

    def create_cost_type(params)
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

    def create_cost(params)
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
      repo.get(:rmt_deliveries, :delivery_tipped, id)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::RmtDelivery.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def create_rmt_delivery_cost(id, params)
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

    def check_existing_mrl_result_for(delivery_id)
      arr = %i[puc_id cultivar_id season_id]
      args = mrl_result_repo.mrl_result_attrs_for(delivery_id, arr)
      existing_id = mrl_result_repo.look_for_existing_mrl_result_id(args)
      return failed_response("There is no existing mrl result for delivery id #{delivery_id}") if existing_id.nil?

      success_response('Found existing mrl result', args.merge({ existing_id: existing_id }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
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

    def insp_repo
      @insp_repo ||= FinishedGoodsApp::GovtInspectionRepo.new
    end

    def mrl_result_repo
      @mrl_result_repo ||= QualityApp::MrlResultRepo.new
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

    def validate_tripsheet_params(params)
      FinishedGoodsApp::TripsheetSchema.call(params)
    end

    def validate_vehicle_job_unit_params(params)
      FinishedGoodsApp::VehicleJobUnitSchema.call(params)
    end
  end
end
