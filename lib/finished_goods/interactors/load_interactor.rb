# frozen_string_literal: true

module FinishedGoodsApp
  class LoadInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def validate_load(load_id)
      load_validator.validate_load(load_id)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def validate_load_truck(load_id)
      load_validator.validate_load_truck(load_id)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_load(params)
      res = LoadServiceSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

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

    def update_load(params)
      res = LoadServiceSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      load_res = nil
      repo.transaction do
        load_res = UpdateLoad.call(res, @user)
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

    def ship_load(id)
      res = nil
      repo.transaction do
        res = ShipLoad.call(id, @user)
        send_po_edi(id)

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

    def allocate_multiselect(load_id, pallet_numbers, initial_pallet_numbers = nil) # rubocop:disable Metrics/AbcSize
      load_validator.validate_allocate_list(load_id, pallet_numbers) unless pallet_numbers.empty?

      new_allocation = pallet_numbers
      current_allocation = repo.select_values(:pallets, :pallet_number, load_id: load_id)

      unless initial_pallet_numbers.nil?
        return failed_response('Allocation mismatch') unless current_allocation.sort == initial_pallet_numbers.sort
      end

      repo.transaction do
        AllocatePallets.call(load_id, new_allocation - current_allocation, @user)
        UnallocatePallets.call(load_id, current_allocation - new_allocation, @user)

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
      load_validator.validate_allocate_list(load_id, pallet_numbers)

      repo.transaction do
        AllocatePallets.call(load_id, pallet_numbers, @user)

        log_transaction
      end
      success_response("Allocation applied to load: #{load_id}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def truck_arrival(params) # rubocop:disable Metrics/AbcSize
      vehicle_res = LoadVehicleSchema.call(params)
      return validation_failed_response(vehicle_res) unless vehicle_res.messages.empty?

      # load has a container
      container_res = nil
      if params[:container] == 't'
        container_res = LoadContainerSchema.call(params)
        return validation_failed_response(container_res) unless container_res.messages.nil_or_empty?
      end

      res = nil
      repo.transaction do
        res = TruckArrival.call(vehicle_res, container_res, @user)
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
      load_validator.validate_allocate_list(load_id, pallet_number)

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
      load_validator.validate_pallets(:exists, pallet_number)

      repo.transaction do
        id = repo.get_id(:pallets, pallet_number: pallet_number)
        repo.update(:pallets, id, temp_tail: params[:temp_tail])
        log_transaction
      end
      success_response("Updated pallet: #{pallet_number}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def find_load_with(pallet_number)
      res = MesscadaApp::ParseString.call(pallet_number)
      raise Crossbeams::InfoError, res.message unless res.success

      load_validator.validate_pallets(:exists, pallet_number)

      load_id = repo.get_value(:pallets, :load_id, pallet_number: pallet_number)
      raise Crossbeams::InfoError, 'Pallet not on a load.' if load_id.nil?

      success_response('ok', load_id)
    rescue Crossbeams::InfoError => e
      validation_failed_response(messages: { pallet_number: [e.message] })
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Load.call(task, id, @user)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def load_validator
      LoadValidator.new
    end

    private

    def repo
      @repo ||= LoadRepo.new
    end

    def load_entity(id)
      repo.find_load_flat(id)
    end
  end
end
