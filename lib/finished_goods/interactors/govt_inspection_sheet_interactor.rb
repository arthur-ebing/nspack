# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionSheetInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_govt_inspection_sheet(params) # rubocop:disable Metrics/AbcSize
      params[:created_by] ||= @user.user_name
      res = validate_govt_inspection_sheet_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_govt_inspection_sheet(res)
        log_status(:govt_inspection_sheets, id, 'CREATED')
        log_transaction
      end
      instance = govt_inspection_sheet(id)
      success_response("Created govt inspection sheet #{instance.booking_reference}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { booking_reference: ['This govt inspection sheet already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_govt_inspection_sheet(id, params)
      res = validate_govt_inspection_sheet_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_govt_inspection_sheet(id, res)
        log_transaction
      end
      instance = govt_inspection_sheet(id)
      success_response("Updated govt inspection sheet #{instance.booking_reference}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_govt_inspection_sheet(id)
      name = govt_inspection_sheet(id).booking_reference
      repo.transaction do
        repo.delete_govt_inspection_sheet(id)
        log_status(:govt_inspection_sheets, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted govt inspection sheet #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def add_pallets_govt_inspection_sheet(params)
      res = validate_add_pallet_govt_inspection_params(params)
      return res unless res.success

      repo.transaction do
        repo.create_govt_inspection_pallet(res.instance)
      end
      success_response('Added pallet to sheet.')
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { failure_remarks: ['This govt inspection pallet already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def complete_govt_inspection_sheet(id)
      res = repo.exists?(:govt_inspection_pallets, govt_inspection_sheet_id: id)
      return failed_response('Inspection sheet must have at least one pallet attached.') unless res

      repo.update_govt_inspection_sheet(id, completed: true)
      log_status(:govt_inspection_sheets, id, 'COMPLETED')

      success_response('Completed sheet.')
    end

    def reopen_govt_inspection_sheet(id)
      repo.update_govt_inspection_sheet(id, completed: false)
      log_status(:govt_inspection_sheets, id, 'REOPENED')

      success_response('Reopened sheet.')
    end

    def finish_govt_inspection_sheet(id) # rubocop:disable Metrics/AbcSize
      res = repo.validate_govt_inspection_sheet_inspect_params(id)
      return res unless res.success

      reinspection = repo.get(:govt_inspection_sheets, id, :reinspection)
      status = reinspection ? 'MANUALLY REINSPECTED BY GOVT' : 'MANUALLY INSPECTED BY GOVT'
      attrs = { inspected: true, results_captured: true, results_captured_at: Time.now }

      repo.transaction do
        repo.update_govt_inspection_sheet(id, attrs)
        log_status(:govt_inspection_sheets, id, status)

        repo.all_hash(:govt_inspection_pallets, govt_inspection_sheet_id: id).each do |govt_inspection_pallet|
          pallet = repo.find_hash(:pallets, govt_inspection_pallet[:pallet_id])
          params = { inspected: true, govt_inspection_passed: govt_inspection_pallet[:passed], last_govt_inspection_pallet_id: govt_inspection_pallet[:id] }
          params[:govt_first_inspection_at] = Time.now if pallet[:govt_first_inspection_at].nil?
          params[:in_stock] = govt_inspection_pallet[:passed]
          params[:stock_created_at] = Time.now if govt_inspection_pallet[:passed]

          repo.update(:pallets, pallet[:id], params)
          log_status(:pallets, pallet[:id], status)
        end
        log_transaction
      end
      success_response('Finished Inspection')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def clone_govt_inspection_sheet(id) # rubocop:disable Metrics/AbcSize
      repo.transaction do
        attrs = (repo.where_hash(:govt_inspection_sheets, id: id) || {})
        attrs = attrs.slice(:inspector_id,
                            :inspection_billing_party_role_id,
                            :exporter_party_role_id,
                            :booking_reference,
                            :inspection_point,
                            :destination_country_id)
        attrs[:cancelled_id] = id
        clone_id = repo.create_govt_inspection_sheet(attrs)
        log_status(:govt_inspection_sheets, clone_id, 'CREATED FROM CANCELLED')

        repo.all_hash(:govt_inspection_pallets, govt_inspection_sheet_id: id).each do |govt_inspection_pallet|
          params = { pallet_id: govt_inspection_pallet[:pallet_id],  govt_inspection_sheet_id: clone_id }
          repo.create_govt_inspection_pallet(params)
        end

        log_transaction
      end
      success_response('Cancelled Inspection')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def cancel_govt_inspection_sheet(id) # rubocop:disable Metrics/AbcSize
      attrs = { cancelled: true, cancelled_at: Time.now }
      repo.transaction do
        clone_govt_inspection_sheet(id)
        repo.update_govt_inspection_sheet(id, attrs)
        log_status(:govt_inspection_sheets, id, 'CANCELLED')
        govt_inspection_pallets = repo.all_hash(:govt_inspection_pallets,  govt_inspection_sheet_id: id)
        govt_inspection_pallets.each do |govt_inspection_pallet|
          attrs = { inspected: nil, govt_inspection_passed: nil, last_govt_inspection_pallet_id: nil, in_stock: nil, stock_created_at: nil }
          repo.update(:pallets, govt_inspection_pallet[:pallet_id], attrs)
          log_status(:pallets, govt_inspection_pallet[:pallet_id], 'INSPECTION CANCELLED')
        end
        log_transaction
      end
      success_response('Cancelled Inspection')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_intake_tripsheet(govt_inspection_sheet_id, params) # rubocop:disable Metrics/AbcSize
      res = validate_vehicle_job_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        vehicle_job_id = repo.create_vehicle_job(res)
        govt_inspection_pallets = repo.all_hash(:govt_inspection_pallets,  govt_inspection_sheet_id: govt_inspection_sheet_id)
        pallet_stock_type_id = MesscadaApp::MesscadaRepo.new.find_stock_type('PALLET')[:id]
        govt_inspection_pallets.each do |govt_inspection_pallet|
          unit_res = validate_vehicle_job_unit_params(stock_item_id: govt_inspection_pallet[:pallet_id], stock_type_id: pallet_stock_type_id,
                                                      vehicle_job_id: vehicle_job_id)
          raise unit_res.messages.to_s unless unit_res.messages.empty?

          repo.create_vehicle_job_unit(unit_res)
          log_status(:pallets, govt_inspection_pallet[:pallet_id], 'ADDED TO INTAKE TRIPSHEET')
        end
        repo.update(:govt_inspection_sheets, govt_inspection_sheet_id, tripsheet_created: true, tripsheet_created_at: Time.now)
        log_status(:govt_inspection_sheets, govt_inspection_sheet_id, 'FIRST INTAKE TRIP SHEET CREATED')
        log_transaction
      end
      success_response('Intake Tripsheet Created')
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def load_vehicle(govt_inspection_sheet_id) # rubocop:disable Metrics/AbcSize
      repo.transaction do
        vehicle_job_id = repo.get_id(:vehicle_jobs, govt_inspection_sheet_id: govt_inspection_sheet_id)
        repo.update(:vehicle_jobs, vehicle_job_id, loaded_at: Time.now)
        repo.load_vehicle_job_units(vehicle_job_id)
        repo.update(:govt_inspection_sheets, govt_inspection_sheet_id, tripsheet_loaded: true, tripsheet_loaded_at: Time.now)
        log_multiple_statuses(:pallets, repo.get_tripsheet_pallet_ids(vehicle_job_id), 'LOADED ON VEHICLE')
        log_status(:govt_inspection_sheets, govt_inspection_sheet_id, 'LOADED ON VEHICLE')
      end

      success_response('Vehicle Loaded Successfully')
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def offloading_started?(govt_inspection_sheet_id)
      offloaded_pallets = repo.offloaded_vehicle_pallets(govt_inspection_sheet_id)
      success_response('ok', offloaded_pallets: offloaded_pallets)
    end

    def cancel_tripsheet(govt_inspection_sheet_id) # rubocop:disable Metrics/AbcSize
      return failed_response('Tripsheet has already been offloaded') if repo.get(:govt_inspection_sheets, govt_inspection_sheet_id, :tripsheet_offloaded)

      repo.transaction do
        vehicle_job_id = repo.get_id(:vehicle_jobs, govt_inspection_sheet_id: govt_inspection_sheet_id)
        tripsheet_pallets = repo.get_tripsheet_pallet_ids(vehicle_job_id)
        repo.delete_vehicle_job(vehicle_job_id)
        repo.update(:govt_inspection_sheets, govt_inspection_sheet_id, tripsheet_created: false, tripsheet_created_at: nil, tripsheet_loaded: false, tripsheet_loaded_at: nil)
        log_multiple_statuses(:pallets, tripsheet_pallets, 'INTAKE TRIP SHEET CANCELED')
        log_status(:govt_inspection_sheets, govt_inspection_sheet_id, 'INTAKE TRIP SHEET CANCELED')
      end

      success_response 'Tripsheet deleted successfully'
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def refresh_tripsheet(govt_inspection_sheet_id) # rubocop:disable Metrics/AbcSize
      vehicle_job_id = repo.get_id(:vehicle_jobs, govt_inspection_sheet_id: govt_inspection_sheet_id)
      govt_inspection_pallets = repo.all_hash(:govt_inspection_pallets,  govt_inspection_sheet_id: govt_inspection_sheet_id)
      tripsheet_pallets = repo.get_vehicle_job_units(vehicle_job_id)

      unless tripsheet_pallets.map { |p| p[:stock_item_id] }.sort == govt_inspection_pallets.map { |p| p[:pallet_id] }.sort
        remove_vehicle_job_units = tripsheet_pallets.map { |p| p[:stock_item_id] } - govt_inspection_pallets.map { |p| p[:pallet_id] }
        new_vehicle_job_units = govt_inspection_pallets.map { |p| p[:pallet_id] } - tripsheet_pallets.map { |p| p[:stock_item_id] }

        repo.transaction do
          repo.delete(:vehicle_job_units, tripsheet_pallets.find_all { |p| remove_vehicle_job_units.include?(p[:stock_item_id]) }.map { |o| o[:id] }) unless remove_vehicle_job_units.empty?
          pallet_stock_type_id = MesscadaApp::MesscadaRepo.new.find_stock_type('PALLET')[:id]
          new_vehicle_job_units.each do |new_vehicle_job_unit|
            unit_res = validate_vehicle_job_unit_params(stock_item_id: new_vehicle_job_unit, stock_type_id: pallet_stock_type_id,
                                                        vehicle_job_id: vehicle_job_id)
            raise unit_res.messages.to_s unless unit_res.messages.empty?

            repo.create_vehicle_job_unit(unit_res)
            log_status(:pallets, new_vehicle_job_unit, 'ADDED TO INTAKE TRIPSHEET')
          end
          log_status(:govt_inspection_sheets, govt_inspection_sheet_id, 'TRIPSHEET REFRESHED')

          complete_offload_vehicle(vehicle_job_id) if repo.tripsheet_offload_complete?(vehicle_job_id)
        end
      end

      success_response('Vehicle Refreshed Successfully')
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def validate_offload_vehicle(vehicle_job_id, location, location_scan_field) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      vehicle_job = repo.find_vehicle_job(vehicle_job_id)
      return failed_response('Tripsheet does not exist') unless vehicle_job

      return failed_response('Tripsheet has already been offloaded') if vehicle_job[:offloaded_at]
      return failed_response('Vehicle not loaded') unless vehicle_job[:loaded_at]

      location_id = locn_repo.resolve_location_id_from_scan(location, location_scan_field)
      return failed_response('Location does not exist') unless !location_id.nil_or_empty? && repo.exists?(:locations, id: location_id)

      location = locn_repo.find_location(location_id)
      return failed_response('Location does not store pallets') unless location[:storage_type_code] == 'PALLETS'
      return failed_response("Incorrect location scanned. Scanned tripsheet is destined for:#{locn_repo.find_location(vehicle_job[:planned_location_to_id])[:location_long_code]}") unless location_id == vehicle_job[:planned_location_to_id]

      success_response('')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def offload_vehicle_pallet(pallet_number) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      pallet = ProductionApp::ProductionRunRepo.new.find_pallet_by_pallet_number(pallet_number)
      return failed_response('Pallet does not exist') unless pallet
      return failed_response('Pallet has been scrapped') if pallet[:scrapped]
      return failed_response('Pallet has been shipped') if pallet[:shipped]

      vehicle_job_unit = repo.find_vehicle_job_unit_by(:stock_item_id, pallet[:id])
      return failed_response('Pallet is not on tripsheet') unless vehicle_job_unit

      instance = { vehicle_job_offloaded: false, vehicle_job_id: vehicle_job_unit[:vehicle_job_id] }
      unless vehicle_job_unit[:offloaded_at]
        repo.transaction do
          tripsheet_pallets = repo.get_vehicle_job_units(vehicle_job_unit[:vehicle_job_id])
          repo.update(:vehicle_job_units, vehicle_job_unit[:id], offloaded_at: Time.now)
          if (tripsheet_pallets.all.find_all { |p| !p[:offloaded_at] }).empty?
            #------------------------------------------------------------------------------------------------------------------------------------
            location_to_id = complete_offload_vehicle(vehicle_job_unit[:vehicle_job_id])
            instance.store(:vehicle_job_offloaded, true)
            instance.store(:pallets_moved, tripsheet_pallets.all.size)
            instance.store(:location, repo.get(:locations, location_to_id, :location_long_code))
          end
        end
      end

      success_response('Pallet Offloaded Successfully', instance)
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def complete_offload_vehicle(vehicle_job_id) # rubocop:disable Metrics/AbcSize
      govt_inspection_sheet_id = repo.get(:vehicle_jobs, vehicle_job_id, :govt_inspection_sheet_id)
      repo.update(:vehicle_jobs, vehicle_job_id, offloaded_at: Time.now)
      repo.update(:govt_inspection_sheets, govt_inspection_sheet_id, tripsheet_offloaded: true, tripsheet_affloaded_at: Time.now)
      location_to_id = repo.get(:vehicle_jobs, vehicle_job_id, :planned_location_to_id)
      tripsheet_pallets = repo.get_vehicle_job_units(vehicle_job_id)
      tripsheet_pallets.each do |p|
        res = FinishedGoodsApp::MoveStockService.new(AppConst::PALLET_STOCK_TYPE, p[:stock_item_id], location_to_id, 'MOVE_PALLET', nil).call
        raise res.message unless res.success
      end
      repo.update(:pallets, tripsheet_pallets.map { |p| p[:stock_item_id] }, in_stock: true, stock_created_at: Time.now) if AppConst::CREATE_STOCK_AT_FIRST_INTAKE
      log_status(:govt_inspection_sheets, govt_inspection_sheet_id, 'TRIPSHEET OFFLOADED')

      location_to_id
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::GovtInspectionSheet.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= GovtInspectionRepo.new
    end

    def locn_repo
      MasterfilesApp::LocationRepo.new
    end

    def govt_inspection_sheet(id)
      repo.find_govt_inspection_sheet(id)
    end

    def validate_vehicle_job_params(params)
      VehicleJobSchema.call(params)
    end

    def validate_vehicle_job_unit_params(params)
      VehicleJobUnitSchema.call(params)
    end

    def validate_govt_inspection_sheet_params(params)
      GovtInspectionSheetSchema.call(params)
    end

    def check_pallets(check, pallet_numbers)
      MesscadaApp::TaskPermissionCheck::Pallets.call(check, pallet_numbers)
    end

    def validate_add_pallet_govt_inspection_params(params) # rubocop:disable Metrics/AbcSize
      res = GovtInspectionAddPalletSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      attrs = res.to_h
      pallet_number = attrs.delete(:pallet_number)

      %i[not_shipped not_failed_otmc verification_passed pallet_weight].each do |check|
        res = check_pallets(check, pallet_number)
        return res unless res.success
      end

      res = if repo.get(:govt_inspection_sheets, attrs[:govt_inspection_sheet_id], :reinspection)
              check_pallets(:not_inspected, pallet_number)
            else
              check_pallets(:not_on_inspection_sheet, pallet_number)
            end
      return res unless res.success

      attrs[:pallet_id] = repo.get_id(:pallets, pallet_number: pallet_number)
      success_response('Passed Validation', attrs)
    end
  end
end
