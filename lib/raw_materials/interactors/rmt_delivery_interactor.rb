# frozen_string_literal: true

module RawMaterialsApp
  class RmtDeliveryInteractor < BaseInteractor # rubocop:disable ClassLength
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
        log_status('rmt_deliveries', id, 'DELIVERY_RECEIVED')
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

    def update_rmt_delivery(id, params) # rubocop:disable Metrics/AbcSize
      params[:date_delivered] = rmt_delivery(id).date_delivered
      params[:season_id] = get_rmt_delivery_season(params[:cultivar_id], params[:date_delivered]) unless params[:cultivar_id].nil_or_empty? || params[:date_delivered].to_s.nil_or_empty?
      res = validate_rmt_delivery_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      validation = child_bins_cultivars_still_valid?(id, params[:orchard_id])
      return failed_response('Delivery could not be updated: delivery orchard is out of sync with bins orchard') unless validation

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

    def child_bins_cultivars_still_valid?(id, delivery_orchard_id)
      delivery_cultivars = lookup_orchard_cultivars(delivery_orchard_id).map { |p| p[1] }
      bins_cultivars = repo.find_delivery_untipped_bins(id).map { |p| p[:cultivar_id] }

      (bins_cultivars.uniq - delivery_cultivars).empty?
    end

    def delete_rmt_delivery(id)
      repo.transaction do
        repo.delete_rmt_delivery(id)
        log_status('rmt_deliveries', id, 'DELETED')
        log_transaction
      end
      success_response('Deleted rmt delivery')
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
        repo.update_rmt_delivery(id, keep_open: true)
        log_transaction
      end
      instance = rmt_delivery(id)
      return failed_response('Delivery: Could Not Be Opened', instance) unless instance.keep_open

      success_response('Delivery: Has Been Opened', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def close_delivery(id)
      repo.transaction do
        repo.update_rmt_delivery(id, keep_open: false)
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
  end
end
