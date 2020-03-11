# frozen_string_literal: true

module FinishedGoodsApp
  class LoadInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
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
      pallet_numbers = repo.find_pallet_numbers_from(load_id: load_id)
      return failed_response 'No pallets allocated' if pallet_numbers.empty?

      res = validate_pallets(:has_nett_weight, pallet_numbers)
      return res unless res.success

      res = validate_pallets(:has_gross_weight, pallet_numbers)
      return res unless res.success

      res = validate_pallets(:not_shipped, pallet_numbers)
      return res unless res.success

      ok_response
    end

    def create_load(params, user)
      res = validate_service_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      load_res = nil
      repo.transaction do
        load_res = FinishedGoodsApp::CreateLoad.call(res, user)
        raise Crossbeams::InfoError, load_res.message unless load_res.success

        log_transaction
      end
      load_res
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_load(params, user)
      res = validate_service_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      load_res = nil
      repo.transaction do
        load_res = FinishedGoodsApp::UpdateLoad.call(res, user)
        raise Crossbeams::InfoError, load_res.message unless load_res.success

        log_transaction
      end
      load_res
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_load(id)
      load_voyage_id = repo.get_id(:load_voyages, load_id: id)
      repo.transaction do
        # DELETE LOAD_VOYAGE
        LoadVoyageRepo.new.delete_load_voyage(load_voyage_id)
        log_status(:load_voyages, load_voyage_id, 'DELETED')

        # DELETE LOAD
        repo.delete_load(id)
        log_status(:loads, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted load: #{id}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def send_po_edi(load_id)
      EdiApp::SendEdiOut.call(AppConst::EDI_FLOW_PO, load_entity(load_id).customer_party_role_id, @user.user_name, load_id)
    end

    def ship_load(id) # rubocop:disable Metrics/AbcSize
      return failed_response("Load: #{id} already shipped.") if load_entity(id)&.shipped

      res = nil
      repo.transaction do
        res = ShipLoad.call(id, @user.user_name)
        raise Crossbeams::InfoError, res.message unless res.success

        send_po_edi(id)

        log_transaction
      end
      success_response(res.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def unship_load(id, pallet_number = nil) # rubocop:disable Metrics/AbcSize
      return failed_response("Load: #{id} not shipped.") unless load_entity(id)&.shipped

      unless pallet_number.nil?
        res = validate_pallets(:shipped, pallet_number)
        return res unless res.success
      end

      res = nil
      repo.transaction do
        res = UnshipLoad.call(id, @user.user_name, pallet_number)
        raise Crossbeams::InfoError, res.message unless res.success

        log_transaction
      end
      success_response(res.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def allocate_multiselect(load_id, params, initial_params = nil) # rubocop:disable Metrics/AbcSize
      pallet_numbers = repo.find_pallet_numbers_from(params)
      unless pallet_numbers.empty?
        res = validate_allocate_list(load_id, pallet_numbers)
        return res unless res.success
      end

      new_allocation = repo.find_pallet_ids_from(pallet_number: pallet_numbers)
      current_allocation = repo.find_pallet_ids_from(load_id: load_id)

      unless initial_params.nil?
        initial_allocation = repo.find_pallet_ids_from(initial_params)
        return failed_response('Allocation mismatch') unless current_allocation.sort == initial_allocation.sort
      end

      repo.transaction do
        repo.allocate_pallets(load_id, new_allocation - current_allocation, @user.user_name)
        repo.unallocate_pallets(load_id, current_allocation - new_allocation, @user.user_name)
        log_transaction
      end
      success_response("Allocation applied to load: #{load_id}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def allocate_list(load_id, pallets_string) # rubocop:disable Metrics/AbcSize
      res = MesscadaApp::ParseString.call(pallets_string)
      return res unless res.success

      pallet_numbers = res.instance
      res = validate_allocate_list(load_id, pallet_numbers)
      return validation_failed_response(messages: { pallet_list: [res.message] }) unless res.success

      pallet_ids = repo.select_values(:pallets, :id, pallet_number: pallet_numbers)
      repo.transaction do
        res = repo.allocate_pallets(load_id, pallet_ids, @user.user_name)
        raise Crossbeams::InfoError, res.message unless res.success

        log_transaction
      end
      success_response("Allocation applied to load: #{load_id}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def truck_arrival(params) # rubocop:disable Metrics/AbcSize
      vehicle_res = validate_load_vehicle_params(params)
      return validation_failed_response(vehicle_res) unless vehicle_res.messages.empty?

      # load has a container
      container_res = nil
      if params[:container] == 't'
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
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def stepper(step_key)
      @stepper ||= LoadStep.new(step_key, @user, @context.request_ip)
    end

    def stepper_allocate_pallet(step_key, load_id, pallet_number)
      res = validate_allocate_list(load_id, pallet_number)
      return res unless res.success

      message = stepper(step_key).allocate_pallet(pallet_number)
      failed_response('error') if stepper(step_key).error?

      success_response(message)
    end

    def stepper_load_pallet(step_key, load_id, pallet_number)
      message = stepper(step_key).load_pallet(pallet_number)
      return failed_response('Error') if stepper(step_key).error?

      return success_response(message) unless stepper(step_key).ready_to_ship?

      res = ship_load(load_id)
      if res.success
        success_response(res.message, load_complete: true)
      else
        failed_response(res.message)
      end
    end

    def update_pallets_temp_tail(params) # rubocop:disable Metrics/AbcSize
      pallet_number = MesscadaApp::ScannedPalletNumber.new(scanned_pallet_number: params[:pallet_number]).pallet_number
      id = repo.get_id(:pallets, pallet_number: pallet_number)
      return failed_response("Pallet: #{pallet_number} doesn't exist.") if id.nil?

      repo.transaction do
        repo.update(:pallets, id, temp_tail: params[:temp_tail])
        log_transaction
      end
      success_response("Updated pallet: #{pallet_number}")
    rescue Crossbeams::InfoError => e
      failed_response(e)
    end

    def find_load_with(pallet_number)
      res = MesscadaApp::ParseString.call(pallet_number)
      return validation_failed_response(messages: { pallet_number: [res.message] }) unless res.success

      res = validate_pallets(:exists, pallet_number)
      return validation_failed_response(messages: { pallet_number: [res.message] }) unless res.success

      load_id = repo.get_with_args(:pallets, :load_id, pallet_number: pallet_number)
      return validation_failed_response(messages: { pallet_number: ['Pallet not on a load.'] }) if load_id.nil?

      success_response('ok', load_id)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Load.call(task, id, @user)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= LoadRepo.new
    end

    def load_entity(id)
      repo.find_load_flat(id)
    end

    def validate_pallets(check, pallet_numbers, load_id = nil)
      MesscadaApp::TaskPermissionCheck::ValidatePallets.call(check, pallet_numbers, load_id)
    end

    def validate_service_params(params)
      LoadServiceSchema.call(params)
    end

    def validate_load_vehicle_params(params)
      LoadVehicleSchema.call(params)
    end

    def validate_load_container_params(params)
      LoadContainerSchema.call(params)
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
  end
end
