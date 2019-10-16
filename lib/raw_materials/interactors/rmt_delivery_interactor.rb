# frozen_string_literal: true

module RawMaterialsApp
  class RmtDeliveryInteractor < BaseInteractor
    def create_rmt_delivery(params) # rubocop:disable Metrics/AbcSize
      assert_permission!(:create)
      if !params[:cultivar_id].nil_or_empty? && !params[:date_delivered].nil_or_empty?
        params[:season_id] = get_rmt_delivery_season(params[:cultivar_id], params[:date_delivered])
        return failed_response("Season not found for selected cultivar and delivery_date:#{params[:date_delivered]}") if params[:season_id].nil_or_empty?
      end

      res = validate_rmt_delivery_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_rmt_delivery(res)
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
      params[:season_id] = get_rmt_delivery_season(params[:cultivar_id], params[:date_delivered])
      res = validate_rmt_delivery_params(params)
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

    def recalc_rmt_bin_nett_weight(id) # rubocop:disable Metrics/AbcSize
      # Ask Hans - Why this condition???
      # return failed_response('No bin nett weights were calculated') unless AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL == 'true'

      repo.transaction do
        rmt_bins = repo.find_bins_by_delivery_id(id)
        rmt_bins.each do |rmt_bin|
          tare_weight = repo.get_rmt_bin_tare_weight(rmt_bin)
          # Ask Hans - Do calc for tipped bins????
          repo.update_rmt_bin(rmt_bin[:id], nett_weight: (rmt_bin[:gross_weight] - tare_weight)) if rmt_bin[:gross_weight] && tare_weight && !rmt_bin[:nett_weight]
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
