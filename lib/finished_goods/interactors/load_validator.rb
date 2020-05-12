# frozen_string_literal: true

module FinishedGoodsApp
  class LoadValidator
    include Crossbeams::Responses
    def validate_load(load_id)
      raise Crossbeams::InfoError, "Value #{load_id} is too big to be a load. Perhaps you scanned a pallet number?" if load_id.to_i > AppConst::MAX_DB_INT

      instance = repo.find_load_flat(load_id)
      raise Crossbeams::InfoError, "Load: #{load_id} doesn't exist." if instance.nil?

      raise Crossbeams::InfoError, "Load: #{load_id} already Shipped." if instance.shipped

      success_response('ok', instance)
    end

    def validate_load_truck(load_id)
      validate_load(load_id)
      instance = repo.find_load_flat(load_id)
      raise Crossbeams::InfoError, "Load: #{load_id}, No Pallets Allocated." unless instance.allocated

      raise Crossbeams::InfoError, "Load: #{load_id}, Truck Arrival hasn't been done." if instance.vehicle_number.nil?

      pallet_numbers = repo.select_values(:pallets, :pallet_number, load_id: load_id)
      validate_pallets(:has_nett_weight, pallet_numbers)
      validate_pallets(:has_gross_weight, pallet_numbers)
      validate_pallets(:not_shipped, pallet_numbers)

      success_response('ok')
    end

    def validate_allocate_list(load_id, pallet_numbers)
      validate_pallets(:not_on_load, pallet_numbers, load_id)
      validate_pallets(:not_shipped, pallet_numbers)
      validate_pallets(:in_stock, pallet_numbers)
      validate_pallets(:not_failed_otmc, pallet_numbers)

      success_response('ok')
    end

    def validate_pallets(check, pallet_numbers, load_id = nil)
      MesscadaApp::TaskPermissionCheck::ValidatePallets.call(check, pallet_numbers, load_id)
    end

    private

    def repo
      @repo ||= LoadRepo.new
    end
  end
end
