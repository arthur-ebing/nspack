# frozen_string_literal: true

module FinishedGoodsApp
  class LoadInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_load(params)
      res = LoadServiceSchema.call(params)
      return validation_failed_response(res) if res.failure?

      load_res = nil
      repo.transaction do
        load_res = CreateLoad.call(res, @user)
        raise Crossbeams::InfoError, load_res.message unless load_res.success

        log_transaction
      end
      load_res
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_load(id, params)
      res = LoadServiceSchema.call(params)
      return validation_failed_response(res) if res.failure?

      load_res = nil
      repo.transaction do
        load_res = UpdateLoad.call(id, res, @user)
        raise Crossbeams::InfoError, load_res.message unless load_res.success

        log_transaction
      end
      load_res
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_load(id) # rubocop:disable Metrics/AbcSize
      check!(:delete, id)

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

    def delete_load_vehicle(id) # rubocop:disable Metrics/AbcSize
      check!(:delete_load_vehicle, id)

      vehicle_id = repo.get_id(:load_vehicles, load_id: id)
      container_id = repo.get_id(:load_containers, load_id: id)

      repo.transaction do
        if container_id
          repo.delete(:load_containers, container_id)
          log_status(:load_containers, container_id, 'DELETED')
        end

        repo.delete(:load_vehicles, vehicle_id)
        log_status(:load_vehicles, vehicle_id, 'DELETED')
        log_transaction
      end
      success_response("Deleted load vehicle for Load: #{id}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def send_edi(load_id)
      load_entity = load_entity(load_id)
      flow_type = load_entity.rmt_load ? AppConst::EDI_FLOW_PALBIN : AppConst::EDI_FLOW_PO
      EdiApp::SendEdiOut.call(flow_type, load_entity.customer_party_role_id, @user.user_name, load_id)
    end

    def allocate_multiselect(load_id, pallet_numbers, initial_pallet_numbers = nil) # rubocop:disable Metrics/AbcSize
      check_pallets!(:allocate, pallet_numbers, load_id) unless pallet_numbers.empty?
      new_allocation = pallet_numbers
      current_allocation = repo.select_values(:pallets, :pallet_number, load_id: load_id)

      unless initial_pallet_numbers.nil?
        return failed_response('Allocation mismatch') unless current_allocation.sort == initial_pallet_numbers.sort
      end

      repo.transaction do
        repo.unallocate_pallets(current_allocation - new_allocation, @user)
        repo.allocate_pallets(load_id, new_allocation - current_allocation, @user)

        log_transaction
      end
      success_response("Allocation applied to load: #{load_id}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def allocate_list(load_id, pallets_string)
      res = MesscadaApp::ParseString.call(pallets_string)
      return res unless res.success

      pallet_numbers = res.instance
      check_pallets!(:allocate, pallet_numbers, load_id)

      repo.transaction do
        repo.allocate_pallets(load_id, pallet_numbers, @user)

        log_transaction
      end
      success_response("Allocation applied to load: #{load_id}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def truck_arrival(id, params) # rubocop:disable Metrics/AbcSize
      vehicle_res = LoadVehicleSchema.call(params)
      return validation_failed_response(vehicle_res) if vehicle_res.failure?

      # load has a container
      container_res = nil
      if params[:container] == 't'
        container_res = LoadContainerSchema.call(params)
        return validation_failed_response(container_res) if container_res.failure?
      end

      res = nil
      repo.transaction do
        res = TruckArrival.call(id, vehicle_res, container_res, @user)

        log_transaction
      end
      success_response(res.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def load_truck(id)
      check!(:load_truck, id)

      repo.transaction do
        repo.update_load(id, loaded: true)
        log_transaction
      end
      success_response("Load: #{id}: Loaded truck")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def unload_truck(id)
      check!(:unload_truck, id)

      repo.transaction do
        repo.update_load(id, loaded: false)
        log_transaction
      end
      success_response("Load: #{id}: Unloaded truck")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_temp_tail(load_id, params) # rubocop:disable Metrics/AbcSize
      pallet_number = MesscadaApp::ScannedPalletNumber.new(scanned_pallet_number: params[:temp_tail_pallet_number]).pallet_number

      pallet_load_id = repo.get_value(:pallets, :load_id, pallet_number: pallet_number)
      return failed_response("Pallet: #{pallet_number} is not on Load: #{load_id}") unless load_id == pallet_load_id

      repo.transaction do
        delete_temp_tail(load_id)

        id = repo.get_id(:pallets, pallet_number: pallet_number)
        repo.update(:pallets, id, temp_tail: params[:temp_tail])
        log_transaction
      end
      success_response("Set temp tail to pallet: #{pallet_number}", load_entity(load_id))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_temp_tail(id)
      check!(:unload_truck, id)

      ids = repo.select_values(:pallets, :id, load_id: id)
      repo.transaction do
        repo.update(:pallets, ids, temp_tail: nil)
        log_transaction
      end
      success_response("Deleted temp tail for Load: #{id}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def ship_load(id)
      res = nil
      repo.transaction do
        res = ShipLoad.call(id, @user)
        send_edi(id)

        log_transaction
      end
      success_response(res.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def unship_load(id, pallet_number = nil)
      res = nil
      repo.transaction do
        res = UnshipLoad.call(id, @user, pallet_number)

        log_transaction
      end
      success_response(res.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_otmc(id)
      otmc_count = nil
      phyto_count = nil
      repo.transaction do
        otmc_count = repo.update_load_otmc_results(id)
        phyto_count = repo.update_load_phyto_data(id)
        log_transaction
      end
      success_response("Updated #{[otmc_count, phyto_count].max} pallet sequences on this load.")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def stepper(step_key)
      @stepper ||= LoadStep.new(step_key, @user, @context.request_ip)
    end

    def stepper_allocate_pallet(step_key, load_id, pallet_number)
      check_pallets!(:allocate, pallet_number, load_id)

      message = stepper(step_key).allocate_pallet(pallet_number)
      failed_response('error') if stepper(step_key).error?

      success_response(message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def stepper_load_pallet(step_key, load_id, pallet_number)
      message = stepper(step_key).load_pallet(pallet_number)
      return failed_response('Error') if stepper(step_key).error?

      return success_response(message) unless stepper(step_key).ready_to_ship?

      res = load_truck(load_id)
      if res.success
        success_response(res.message, load_loaded: true)
      else
        failed_response(res.message)
      end
    end

    def find_load_with(pallet_number)
      res = MesscadaApp::ParseString.call(pallet_number)
      return validation_failed_response(messages: { pallet_number: [res.message] }) unless res.success

      exist = repo.exists?(:pallets, pallet_number: pallet_number)
      return validation_failed_response(messages: { pallet_number: ['Pallet not found.'] }) unless exist

      load_id = repo.get_value(:pallets, :load_id, pallet_number: pallet_number)
      return validation_failed_response(messages: { pallet_number: ['Pallet not on a load.'] }) if load_id.nil?

      success_response('ok', load_id)
    end

    def assert_permission!(task, id = nil, pallet_number = nil)
      res = TaskPermissionCheck::Load.call(task, id, pallet_number)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def check(task, id = nil, pallet_number = nil)
      TaskPermissionCheck::Load.call(task, id, pallet_number)
    end

    private

    def check!(task, id = nil, pallet_number = nil)
      res = TaskPermissionCheck::Load.call(task, id, pallet_number)
      raise Crossbeams::InfoError, res.message unless res.success
    end

    def check_pallets!(check, pallet_numbers, load_id = nil)
      res = MesscadaApp::TaskPermissionCheck::Pallets.call(check, pallet_numbers, load_id)
      raise Crossbeams::InfoError, res.message unless res.success
    end

    def repo
      @repo ||= LoadRepo.new
    end

    def load_entity(id)
      repo.find_load_flat(id)
    end
  end
end
