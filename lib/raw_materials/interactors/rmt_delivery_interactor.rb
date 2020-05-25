# frozen_string_literal: true

module RawMaterialsApp
  class RmtDeliveryInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_rmt_delivery(params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      assert_permission!(:create)
      params[:date_delivered] = Time.now.to_s
      if !params[:cultivar_id].nil_or_empty? && !params[:date_delivered].nil_or_empty?
        params[:season_id] = get_rmt_delivery_season(params[:cultivar_id], params[:date_delivered])
        return failed_response("Season not found for selected cultivar and delivery_date:#{params[:date_delivered]}") if params[:season_id].nil_or_empty?
      end

      res = validate_rmt_delivery_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_rmt_delivery(res)
        repo.delivery_set_current(id) if res[:current]
        log_status(:rmt_deliveries, id, 'DELIVERY_RECEIVED')
        log_transaction
      end
      instance = rmt_delivery(id)
      success_response("Created rmt delivery #{instance.truck_registration_number}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { truck_registration_number: ['This rmt delivery already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def  get_rmt_delivery_season(cultivar_id, date_delivered)
      repo.rmt_delivery_season(cultivar_id, date_delivered)
    end

    def update_rmt_delivery(id, params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      params[:date_delivered] = rmt_delivery(id).date_delivered
      params[:season_id] = get_rmt_delivery_season(params[:cultivar_id], params[:date_delivered]) unless params[:cultivar_id].nil_or_empty? || params[:date_delivered].to_s.nil_or_empty?
      res = validate_rmt_delivery_params(params)
      return failed_response(unwrap_failed_response(validation_failed_response(res))) if !res.messages.empty? && res.messages.one? && res.messages.include?(:season_id)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_rmt_delivery(id, res)
        repo.update_rmt_bins_inherited_field(id, res)
        log_transaction
      end
      instance = rmt_delivery(id)
      success_response("Updated rmt delivery #{instance.truck_registration_number}",
                       instance)
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
                                pallets_affected: bins.map { |b| b[:bin_asset_number] } }

          res = validate_reworks_run_params(reworks_run_attrs)
          return failed_response(unwrap_failed_response(validation_failed_response(res))) unless res.messages.empty?

          create_delete_rmt_delivery_reworks_run(res, before: before, after: after)
          repo.delete_rmt_bin(bins.map { |b| b[:id] })
        end

        repo.delete_rmt_delivery(id)
        log_status(:rmt_deliveries, id, 'DELETED')
        log_transaction
      end
      success_response('Deleted rmt delivery')
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

    def set_receive_date(id, params) # rubocop:disable Metrics/AbcSize
      repo.transaction do
        bins = repo.find_bins_by_delivery_id(id)
        repo.update_rmt_delivery(id, date_delivered: params[:date_received])
        repo.update(:rmt_bins, bins.map { |b| b[:id] }, bin_received_date_time: params[:date_received])
        log_multiple_statuses(:rmt_bins, bins.map { |b| b[:id] }, AppConst::RMT_BIN_RECEIPT_DATE_OVERRIDE)
        log_status(:rmt_deliveries, id, AppConst::RMT_BIN_RECEIPT_DATE_OVERRIDE)
        log_transaction
      end
      instance = rmt_delivery(id)

      success_response('Delivery/Bins: date_delivered/date_delivered have been updated', instance)
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

    def open_delivery(id)
      repo.transaction do
        repo.update_rmt_delivery(id, keep_open: true, delivery_tipped: false)
        log_status(:rmt_deliveries, id, 'DELIVERY OPENED')
        log_transaction
      end
      instance = rmt_delivery(id)
      return failed_response('Delivery: Could Not Be Opened', instance) unless instance.keep_open

      success_response('Delivery: Has Been Opened', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def close_delivery(id)
      changeset = { keep_open: false }
      changeset[:delivery_tipped] = true if repo.all_bins_tipped?(id)

      repo.transaction do
        repo.update_rmt_delivery(id, changeset)
        log_status(:rmt_deliveries, id, 'DELIVERY OPENED')
        log_transaction
      end
      instance = rmt_delivery(id)
      return failed_response('Delivery: Could Not Be Closed', instance) if instance.keep_open

      success_response('Delivery: Has Been Closed', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def recalc_rmt_bin_nett_weight(id) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity
      repo.transaction do
        rmt_bins = repo.find_bins_by_delivery_id(id)
        rmt_bins.each do |rmt_bin|
          tare_weight = repo.get_rmt_bin_tare_weight(rmt_bin)

          if !rmt_bin[:bin_tipped] && rmt_bin[:gross_weight] && tare_weight
            # override nett_weight
            repo.update_rmt_bin(rmt_bin[:id], nett_weight: (rmt_bin[:gross_weight] - tare_weight))
          elsif rmt_bin[:bin_tipped] && rmt_bin[:gross_weight] && tare_weight && !rmt_bin[:nett_weight]
            # only set nett weight if it is null
            repo.update_rmt_bin(rmt_bin[:id], nett_weight: (rmt_bin[:gross_weight] - tare_weight))
          end
        end
      end
      success_response('Bin nett weight calculated successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
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

    private

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
  end
end
