# frozen_string_literal: true

module FinishedGoodsApp
  class LoadInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_load(params) # rubocop:disable Metrics/AbcSize
      res = validate_load_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        load_res = CreateLoadService.call(res, @user.user_name)
        id = load_res.instance
        raise Crossbeams::InfoError, load_res.message unless load_res.success

        log_transaction
      end
      instance = load_entity(id)
      success_response("Created load #{id}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { order_number: ['This load already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_load(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_load_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        load_res = UpdateLoadService.call(id, res, @user.user_name)
        raise Crossbeams::InfoError, load_res.message unless load_res.success

        log_transaction
      end
      instance = load_entity(id)
      success_response("Updated load #{id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def ship_load(id) # rubocop:disable Metrics/AbcSize
      failed_response("Load #{id} already shipped") if load_entity(id)&.shipped
      res = nil
      repo.transaction do
        res = ShipLoad.call(load_id: id, user_name: @user.user_name)
        raise Crossbeams::InfoError, res.message unless res.success

        log_transaction
      end
      success_response(res.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def unship_load(id, pallet_number = nil) # rubocop:disable Metrics/AbcSize
      failed_response("Load #{id} not shipped") unless load_entity(id)&.shipped

      pallet_shipped = repo.validate_pallets(pallet_number, shipped: true) == [pallet_number]
      failed_response("Pallet Number #{pallet_number} not shipped") unless pallet_shipped

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

    def allocate_multiselect(id, pallet_sequence_id) # rubocop:disable Metrics/AbcSize
      pallet_numbers = repo.find_pallet_numbers_from(pallet_sequence_id: pallet_sequence_id)
      validated_pallet_numbers = repo.validate_pallets(pallet_numbers, shipped: false)

      new_allocation = repo.find_pallet_ids_from(pallet_numbers: validated_pallet_numbers)
      current_allocation = repo.find_pallet_ids_from(load_id: id)

      repo.transaction do
        repo.allocate_pallets(id, new_allocation - current_allocation, @user.user_name)
        repo.unallocate_pallets(id, current_allocation - new_allocation, @user.user_name)
        log_transaction
      end
      success_response("Load #{id} has been updated")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def allocate(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_pallet_list(params)
      return validation_failed_response(res) unless res.success

      repo.transaction do
        load_res = repo.allocate_pallets(id, res.instance, @user.user_name)
        raise Crossbeams::InfoError, load_res.message unless load_res.success

        log_transaction
      end
      success_response("Loaded pallets to load #{id} ")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_load(id)
      load_voyage_id = LoadVoyageRepo.new.find_load_voyage_from(load_id: id)
      repo.transaction do
        # DELETE LOAD_VOYAGE
        LoadVoyageRepo.new.delete_load_voyage(load_voyage_id)
        log_status(:load_voyages, load_voyage_id, 'DELETED')

        # DELETE LOAD
        repo.delete_load(id)
        log_status(:loads, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted load #{id}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def validate_load(load_id) # rubocop:disable Metrics/AbcSize
      load = repo.find_load(load_id)
      return failed_response("Load:#{load_id} doesn't exist") if load.nil?

      return failed_response("Load:#{load_id} already Shipped") if load.shipped

      validate_pallets = validate_load_truck_pallets(load_id)
      return failed_response(validate_pallets.message) unless validate_pallets.success

      message << validate_pallets.message unless validate_pallets.success

      ok_response
    end

    def validate_load_truck(load_id) # rubocop:disable Metrics/AbcSize
      load = repo.find_load_flat(load_id)
      return failed_response("Load:#{load_id} doesn't exist") if load.nil?

      message = []
      message << "Truck Arrival hasn't been done" if load.vehicle_number.nil?
      if load.shipped
        message << 'Already Shipped'
      else
        validate_pallets = validate_load_truck_pallets(load_id)
        message << validate_pallets.message unless validate_pallets.success
      end
      return failed_response("Load:#{load_id}\n#{message.join("\n")}") unless message.empty?

      ok_response
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

      ok_response
    end

    def truck_arrival_service(params) # rubocop:disable Metrics/AbcSize
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

    def stepper
      @stepper ||= LoadTruckStep.new(@user, @context.request_ip)
    end

    def current_load_truck
      stepper
    end

    def setup_load_truck(load_id)
      load_flat = LoadRepo.new.find_load_flat(load_id)
      raise 'Setup Load called without load_id' if load_flat.nil?

      form_state = { load_id: load_id,
                     voyage_code: load_flat.voyage_code,
                     vehicle_number: load_flat.vehicle_number,
                     container_code: load_flat.container_code }
      allocated = LoadRepo.new.find_pallet_numbers_from(load_id: load_id)

      stepper.write(form_state: form_state, allocated: allocated, scanned: [])
    end

    def scan_pallet(load_id, scanned_number) # rubocop:disable Metrics/AbcSize
      stepper.scan_pallet(scanned_number)
      return failed_response('error') if stepper.error?

      return ok_response unless stepper.ready_to_load?

      res = ship_load(load_id)
      if res.success
        stepper.clear
        success_response(res.message, load_complete: true)
      else
        failed_response(res.message, load_id)
      end
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Load.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= LoadRepo.new
    end

    def load_entity(id)
      repo.find_load_flat(id)
    end

    def validate_load_params(params)
      LoadSchema.call(params)
    end

    def validate_load_vehicle_params(params)
      LoadVehicleSchema.call(params)
    end

    def validate_load_container_params(params)
      LoadContainerSchema.call(params)
    end

    def validate_pallet_list(params) # rubocop:disable Metrics/AbcSize
      attrs = params[:pallet_list].split(/\n|,/).map(&:strip).reject(&:empty?)
      pallet_numbers = attrs.map { |x| x.gsub(/['"]/, '') }

      errors = pallet_numbers.reject { |x| x.match(/\A\d+\Z/) }
      message = "#{errors.join(', ')} must be numeric"
      return OpenStruct.new(success: false, messages: { pallet_list: [message] }) unless errors.nil_or_empty?

      errors = (pallet_numbers - repo.validate_pallets(pallet_numbers))
      message = "#{errors.join(', ')} doesn't exist"
      return OpenStruct.new(success: false, messages: { pallet_list: [message] }) unless errors.nil_or_empty?

      errors = repo.validate_pallets(pallet_numbers, allocated: true)
      message = "#{errors.join(', ')} already allocated"
      return OpenStruct.new(success: false, messages: { pallet_list: [message] }) unless errors.nil_or_empty?

      errors = repo.validate_pallets(pallet_numbers, shipped: true)
      message = "#{errors.join(', ')} already shipped"
      return OpenStruct.new(success: false, messages: { pallet_list: [message] }) unless errors.nil_or_empty?

      OpenStruct.new(success: true, instance: repo.find_pallet_ids_from(pallet_numbers: pallet_numbers))
    end
  end
end
