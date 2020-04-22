# frozen_string_literal: true

module FinishedGoodsApp
  module LoadValidator
    def validate_load(load_id)
      return failed_response("Value #{load_id} is too big to be a load. Perhaps you scanned a pallet number?") if load_id.to_i > AppConst::MAX_DB_INT

      instance = repo.find_load_flat(load_id)
      return failed_response("Load: #{load_id} doesn't exist.") if instance.nil?

      return failed_response("Load: #{load_id} already Shipped.") if instance.shipped

      success_response('ok', instance)
    end

    def validate_load_truck(load_id)
      res = validate_load(load_id)
      return res unless res.success

      return failed_response("Truck Arrival hasn't been done.") if res.instance.vehicle_number.nil?

      res = validate_load_truck_pallets(load_id)
      return res unless res.success

      ok_response
    end

    def validate_load_truck_pallets(load_id)
      pallet_numbers = repo.select_values(:pallets, :pallet_number, load_id: load_id)
      return failed_response 'No pallets allocated' if pallet_numbers.empty?

      res = validate_pallets(:has_nett_weight, pallet_numbers)
      return res unless res.success

      res = validate_pallets(:has_gross_weight, pallet_numbers)
      return res unless res.success

      res = validate_pallets(:not_shipped, pallet_numbers)
      return res unless res.success

      ok_response
    end

    def validate_allocate_list(load_id, pallet_numbers)
      res = validate_pallets(:not_on_load, pallet_numbers, load_id)
      return res unless res.success

      res = validate_pallets(:not_shipped, pallet_numbers)
      return res unless res.success

      res = validate_pallets(:in_stock, pallet_numbers)
      return res unless res.success

      res = validate_pallets(:not_failed_otmc, pallet_numbers)
      return res unless res.success

      ok_response
    end

    def validate_pallets(check, pallet_numbers, load_id = nil)
      MesscadaApp::TaskPermissionCheck::ValidatePallets.call(check, pallet_numbers, load_id)
    end

    def validate_load_service_params(params)
      LoadServiceSchema.call(params)
    end

    def validate_load_vehicle_params(params)
      LoadVehicleSchema.call(params)
    end

    def validate_load_container_params(params)
      LoadContainerSchema.call(params)
    end

    private

    def repo
      @repo ||= LoadRepo.new
    end
  end
end
