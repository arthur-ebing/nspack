# frozen_string_literal: true

module FinishedGoodsApp
  class LoadInteractor < BaseInteractor
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
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete load. It is still referenced#{e.message.partition('referenced').last}")
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

    def send_hcs_edi(load_id)
      load_entity = load_entity(load_id)
      if load_entity.rmt_load # OR BOTH????
        # EdiApp::SendEdiOut.call(AppConst::EDI_FLOW_HBS, nil, @user.user_name, bin_load_id, context: { fg_load: true }) # OR could we send both????
      else
        EdiApp::SendEdiOut.call(AppConst::EDI_FLOW_HCS, nil, @user.user_name, load_id)
      end
    end

    def send_hbs_edi(load_id)
      load_entity = load_entity(load_id)
      EdiApp::SendEdiOut.call(AppConst::EDI_FLOW_HBS, nil, @user.user_name, bin_load_id, context: { fg_load: true }) if load_entity.rmt_load
    end

    def allocate_multiselect(load_id, pallet_numbers, initial_pallet_numbers = nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      check_pallets!(:allocate, pallet_numbers, load_id) unless pallet_numbers.empty?
      new_allocation = pallet_numbers
      current_allocation = repo.select_values(:pallets, :pallet_number, load_id: load_id)

      unless initial_pallet_numbers.nil?
        return failed_response('Allocation mismatch') unless current_allocation.sort == initial_pallet_numbers.sort
      end

      pallet_numbers = new_allocation - current_allocation
      res = validate_wip_pallet_numbers(pallet_numbers)
      raise Crossbeams::InfoError, unwrap_error_set(res.messages) unless res.success

      repo.transaction do
        repo.unallocate_pallets(current_allocation - new_allocation, @user)
        repo.allocate_pallets(load_id, pallet_numbers, @user)
        FinishedGoodsApp::ProcessOrderLines.call(@user, load_id: load_id)

        if AppConst::CR_FG.lookup_extended_fg_code?
          pallet_ids = repo.select_values(:pallets, :id, pallet_number: pallet_numbers)
          FinishedGoodsApp::Job::CalculateExtendedFgCodesFromSeqs.enqueue(pallet_ids)
        end

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
      check_pallets!(:allocate, pallet_numbers, load_id)

      res = validate_wip_pallet_numbers(pallet_numbers)
      return validation_failed_response(res) unless res.success

      repo.transaction do
        repo.allocate_pallets(load_id, pallet_numbers, @user)
        FinishedGoodsApp::ProcessOrderLines.call(@user, load_id: load_id)

        if AppConst::CR_FG.lookup_extended_fg_code?
          pallet_ids = repo.select_values(:pallets, :id, pallet_number: pallet_numbers)
          FinishedGoodsApp::Job::CalculateExtendedFgCodesFromSeqs.enqueue(pallet_ids)
        end

        log_transaction
      end
      success_response("Allocation applied to load: #{load_id}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def validate_wip_pallet_numbers(pallet_numbers)
      pallet_ids = repo.select_values(:pallets, :id, pallet_number: pallet_numbers)
      res = reworks_repo.are_pallets_out_of_wip?(pallet_ids)

      unless res.success
        msg = "Pallets: #{repo.select_values(:pallets, :pallet_number, id: res.instance).join(', ')} are works in progress"
        return OpenStruct.new(success: false, messages: { pallet_list: [msg] }, pallet_list: pallet_numbers)
      end

      ok_response
    end

    def allocate_grid(load_id)
      pallet_ids = repo.list_pallets_for_load(load_id)
      rpt = dataminer_report('stock_pallets_for_loads.yml', conditions: [{ col: 'pallets.id', op: 'IN', val: pallet_ids }])

      row_defs = dataminer_report_rows(rpt)
      {
        multiselect_ids: repo.select_values(:pallets, :id, load_id: load_id),
        columnDefs: col_defs_for_allocate_grid(rpt),
        rowDefs: row_defs
      }.to_json
    end

    def col_defs_for_allocate_grid(rpt)
      Crossbeams::DataGrid::ColumnDefiner.new(for_multiselect: true).make_columns do |mk|
        mk.action_column do |act|
          act.popup_view_link '/list/stock_pallet_sequences/with_params?key=standard&pallet_id=$col1$',
                              col1: 'id',
                              icon: 'list',
                              text: 'sequences',
                              title: 'Pallet sequences for Pallet No $:pallet_number$'
        end
        dataminer_report_columns(mk, rpt)
      end
    end

    def truck_arrival(id, params)
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

    def ship_load(id) # rubocop:disable Metrics/AbcSize
      res = nil
      repo.transaction do
        res = ShipLoad.call(id, @user)
        raise Crossbeams::InfoError, res.message unless res.success

        send_edi(id) unless repo.get(:loads, :truck_must_be_weighed, id)
        send_hcs_edi(id) if repo.load_is_on_order?(id)
        send_hbs_edi(id)

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
        raise Crossbeams::InfoError, res.message unless res.success

        log_transaction
      end
      success_response(res.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def titan_addendum(id, mode)
      res = nil
      repo.transaction do
        res = TitanAddendum.call(id, mode, @user)
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
        otmc_count = QualityApp::OrchardTestRepo.new.update_otmc_results(load_id: id)
        phyto_count = QualityApp::OrchardTestRepo.new.update_phyto_data(load_id: id)
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

    def add_load_to_order(load_id, order_id)
      res = nil
      repo.transaction do
        res = AddLoadToOrder.call(load_id, order_id, @user)
        log_transaction
      end
      success_response(res.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil, pallet_number = nil)
      res = TaskPermissionCheck::Load.call(task, id, pallet_number)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def check(task, id = nil, pallet_number = nil)
      TaskPermissionCheck::Load.call(task, id, pallet_number)
    end

    def pallet_numbers_from_pallet_ids(pallet_ids)
      repo.select_values(:pallets, :pallet_number, id: pallet_ids).uniq
    end

    def load_entity(id)
      repo.find_load(id)
    end

    def can_ship_load?
      can_ship_load = Crossbeams::Config::UserPermissions.can_user?(@user, :load, :can_ship) unless @user&.permission_tree.nil?
      message = "Cannot change load shipped date. Requires user with 'can_ship' permission"
      raise Crossbeams::InfoError, message unless can_ship_load

      ok_response
    end

    def load_shipped_date_for(load_id)
      repo.get(:loads, :shipped_at, load_id).strftime('%Y-%m-%d')
    end

    def confirm_force_shipped_date(load_id, params) # rubocop:disable Metrics/AbcSize
      res = can_ship_load?
      return res unless res.success

      res = LoadEditShippedDateSchema.call(params)
      return validation_failed_response(res) if res.failure?

      status = "SHIPPED DATE FORCED FROM #{res[:load_shipped_at]} TO #{res[:shipped_at]}"
      pallet_ids = repo.select_values(:pallets, :id, load_id: load_id)
      repo.transaction do
        repo.update_load(load_id, shipped_at: res[:shipped_at])
        repo.update(:pallets, pallet_ids, shipped_at: res[:shipped_at])
        log_multiple_statuses(:pallets, pallet_ids, status)
        log_status(:loads, load_id, status)
        log_transaction
      end
      success_response("Updated shipped date for load: #{load_id} successfully.")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def apply_container_weights(id, params) # rubocop:disable Metrics/AbcSize
      check!(:change_container_weights, id)

      res = LoadContainerWeightSchema.call(params)
      return validation_failed_response(res) if res.failure?

      load_container_id = repo.get_id(:load_containers, load_id: id)
      changed_weights = weights_changed?(load_container_id, res)
      return success_response('Nothing to update - weights were not changed') unless changed_weights

      send_for_weight = repo.get(:loads, :truck_must_be_weighed, id)
      repo.transaction do
        repo.update(:load_containers, load_container_id, res)
        send_edi(id) if send_for_weight

        log_status(:loads, id, 'CONTAINER WEIGHTS SET')
      end

      success_response(send_for_weight ? 'Weights applied to container and EDI has been queued' : 'Weights applied to container')
    end

    private

    def weights_changed?(load_container_id, res)
      rec = repo.where_hash(:load_containers, id: load_container_id)
      change = false
      res.to_h.each do |k, v|
        change = true if rec[k] != v
      end
      change
    end

    def check!(task, id = nil, pallet_number = nil)
      res = TaskPermissionCheck::Load.call(task, id, pallet_number)
      raise Crossbeams::InfoError, res.message unless res.success
    end

    def check_pallets!(check, pallet_numbers, load_id = nil)
      res = MesscadaApp::TaskPermissionCheck::Pallet.call(check, pallet_number: pallet_numbers, load_id: load_id)
      raise Crossbeams::InfoError, res.message unless res.success
    end

    def repo
      @repo ||= LoadRepo.new
    end

    def reworks_repo
      @reworks_repo ||= ProductionApp::ReworksRepo.new
    end
  end
end
