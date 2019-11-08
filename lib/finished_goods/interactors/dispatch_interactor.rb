# frozen_string_literal: true

module FinishedGoodsApp
  class DispatchInteractor < BaseInteractor
    def validate_load(load_id)
      load = repo.find_load(load_id)
      return failed_response("Load:#{load_id} doesn't exist") if (load&.id).nil_or_empty?

      return success_response("Load:#{load_id} already Shipped", load_id: load_id) if load&.shipped

      success_response('ok', load_id)
    end

    def validate_load_truck(load_id) # rubocop:disable Metrics/AbcSize
      load = repo.find_load_flat(load_id)
      p load
      message = []
      message << "Doesn't exist" if load.id.nil_or_empty?
      validate_pallets = validate_load_truck_pallets(load_id)
      message << validate_pallets.message  unless validate_pallets.success
      message << "Truck Arrival hasn't been done"  if load.vehicle_number.nil_or_empty?
      message << 'Already Shipped'  if load.shipped
      return failed_response("Load:#{load_id}\n#{message.join("\n")}") unless message.empty?

      success_response('ok', load_id)
    end

    def validate_load_truck_pallets(load_id) # rubocop:disable Metrics/AbcSize
      pallets = repo.find_pallet_numbers_from(load_id: load_id)
      message = []
      message << 'No pallets allocated' if pallets.nil_or_empty?

      without_nett_weight = repo.validate_pallets(pallets, has_nett_weight: true)
      message << "Pallets:\n#{without_nett_weight.join("\n")}\ndo not have nett weight\n" unless without_nett_weight.nil_or_empty?

      without_gross_weight = repo.validate_pallets(pallets, has_gross_weight: true)
      message << "Pallets:\n#{without_gross_weight.join("\n")}\ndo not have gross weight\n" unless without_gross_weight.nil_or_empty?

      already_shipped = repo.validate_pallets(pallets, shipped: true)
      message << "Pallets:\n#{already_shipped.join("\n")}\nalready Shipped\n" unless already_shipped.nil_or_empty?
      return failed_response(message.join("\n")) unless message.empty?

      success_response('ok')
    end

    def truck_arrival_service(params) # rubocop:disable Metrics/AbcSize
      vehicle_res = validate_load_vehicle_params(params)
      return validation_failed_response(vehicle_res) unless vehicle_res.messages.empty?

      # load has a container
      container_res = nil
      if params[:container] == 'true'
        container_res = validate_load_container_params(params)
        return validation_failed_response(container_res) unless container_res.messages.nil_or_empty?
      end

      res = nil
      repo.transaction do
        res = TruckArrival.call(vehicle_attrs: vehicle_res,
                                container_attrs: container_res,
                                user_name: @user.user_name)
        raise Crossbeams::InfoError, res.message unless res.success

        log_transaction
      end
      success_response(res.message)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { vehicle_number: ['This load vehicle already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= LoadRepo.new
    end

    def validate_load_vehicle_params(params)
      LoadVehicleSchema.call(params)
    end

    def validate_load_container_params(params)
      AppConst::VGM_REQUIRED ? VGM_REQUIRED_Schema.call(params) : LoadContainerSchema.call(params)
    end
  end
end
