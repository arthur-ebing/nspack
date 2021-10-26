# frozen_string_literal: true

module RawMaterialsApp
  class RmtBinInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_bin_tripsheet(planned_location_to_id, move_bins_from_another_tripsheet, vehicle_job_id = nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      res = FinishedGoodsApp::TripsheetContract.new.call(move_bins: move_bins_from_another_tripsheet, from_vehicle_job_id: vehicle_job_id)
      return failed_response(unwrap_failed_response(validation_failed_response(res))) if res.failure?

      if res[:move_bins] && res[:from_vehicle_job_id]
        tripsheet = insp_repo.find_vehicle_job(res[:from_vehicle_job_id])
        return failed_response('Tripsheet does not exist') unless tripsheet
        return failed_response('Tripsheet already offloaded') if tripsheet[:offloaded_at]
        return failed_response('Trisheet already completed') if tripsheet[:loaded_at]
      end

      stock_type_id = repo.get_value(:stock_types, :id, stock_type_code: AppConst::BIN_STOCK_TYPE)
      params = { business_process_id: repo.get_value(:business_processes, :id, process: AppConst::BINS_TRIPSHEET_BUSINESS_PROCESS),
                 stock_type_id: stock_type_id, planned_location_to_id: planned_location_to_id, items_moved_from_job_id: res[:from_vehicle_job_id] }
      res = validate_tripsheet_params(params)
      return failed_response(unwrap_failed_response(validation_failed_response(res))) if res.failure?

      id = nil
      repo.transaction do
        id = insp_repo.create_vehicle_job(res)
        log_transaction
      end
      success_response('Delivery Tripsheet Created', id)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def add_bin_to_tripsheet(vehicle_job_id, bin_number) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      vehicle_job = insp_repo.find_vehicle_job(vehicle_job_id)
      return failed_response('Tripsheet already offloaded') if vehicle_job[:offloaded_at]
      return failed_response('Trisheet already completed') if vehicle_job[:loaded_at]
      return failed_response('Bin Number: must be filled') if bin_number.nil_or_empty?

      stock_type_id = repo.get_value(:stock_types, :id, stock_type_code: AppConst::BIN_STOCK_TYPE)
      bin_id = repo.get_value(:rmt_bins, :id, bin_asset_number: bin_number)
      return failed_response("Bin:#{bin_number} not found") unless bin_id
      return failed_response("Bin:#{bin_number} belongs to another tripsheet") if insp_repo.vehicle_job_unit_in_different_tripsheet?(bin_id, vehicle_job_id) && repo.get_value(:vehicle_job_units, :vehicle_job_id, stock_item_id: bin_id, offloaded_at: nil) != vehicle_job[:items_moved_from_job_id]

      res = validate_vehicle_job_unit_params(stock_item_id: bin_id, stock_type_id: stock_type_id, vehicle_job_id: vehicle_job_id)
      return failed_response(unwrap_failed_response(validation_failed_response(res))) if res.failure?

      msg = 'Bin Added To Tripsheet'
      repo.transaction do
        from_vehicle_job = insp_repo.bin_from_tripsheet(bin_id, vehicle_job[:items_moved_from_job_id])
        if from_vehicle_job
          return failed_response("From Tripsheet: #{vehicle_job[:items_moved_from_job_id]} already loaded") if from_vehicle_job[:loaded_at]
          return failed_response("From Tripsheet: #{vehicle_job[:items_moved_from_job_id]} already offloaded") if from_vehicle_job[:offloaded_at]

          insp_repo.delete_vehicle_job_unit(from_vehicle_job[:vehicle_job_unit_id])
          log_status(:rmt_bins, bin_id, "BIN_MOVED_FROM_SHEET(#{from_vehicle_job[:id]})_TO_SHEET(#{vehicle_job_id})")
        end

        vehicle_job_unit_id = repo.get_value(:vehicle_job_units, :id, stock_item_id: bin_id, vehicle_job_id: vehicle_job_id)
        if vehicle_job_unit_id
          insp_repo.delete_vehicle_job_unit(vehicle_job_unit_id)
          log_status(:rmt_bins, bin_id, AppConst::RMT_BIN_REMOVED_FROM_BINS_TRIPSHEET)
          msg = 'Bin Removed From Tripsheet'
        else
          insp_repo.create_vehicle_job_unit(res)
          log_status(:rmt_bins, bin_id, AppConst::RMT_BIN_ADDED_TO_BINS_TRIPSHEET)
        end
        log_transaction
      end
      success_response(msg)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def cancel_bins_tripheet(vehicle_job_id)
      offloaded_bins = insp_repo.offloaded_vehicle_job_units_size(vehicle_job_id)
      return failed_response("Couldn't cancel tripsheet: #{offloaded_bins} bins have already been offloaded") unless offloaded_bins.zero?

      repo.transaction do
        bins = repo.select_values(:vehicle_job_units, :stock_item_id, vehicle_job_id: vehicle_job_id)
        insp_repo.delete_vehicle_job(vehicle_job_id)
        log_multiple_statuses(:rmt_bins, bins, AppConst::BIN_TRIPSHEET_CANCELED)
      end

      success_response 'Tripsheet deleted successfully'
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def complete_bins_tripsheet(vehicle_job_id)
      repo.transaction do
        repo.update(:vehicle_jobs, vehicle_job_id, loaded_at: Time.now)
        insp_repo.load_vehicle_job_units(vehicle_job_id)
        log_multiple_statuses(:rmt_bins, repo.select_values(:vehicle_job_units, :stock_item_id, vehicle_job_id: vehicle_job_id), AppConst::RMT_BIN_LOADED_ON_VEHICLE)
      end

      success_response 'Tripsheet completed successfully'
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def can_continue_bin_tripsheet(vehicle_job_id)
      res = UtilityFunctions.validate_integer_length(:tripsheet, vehicle_job_id)
      return failed_response("Bin Tripsheet: #{unwrap_error_set(res.errors)}") if res.failure?

      repo.can_continue_bin_tripsheet(vehicle_job_id)
    end

    def validate_bins_tripsheet_to_offload_(vehicle_job_id, location_id) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      stock_type_id = repo.get_value(:stock_types, :id, stock_type_code: AppConst::BIN_STOCK_TYPE)
      vehicle_job = insp_repo.find_vehicle_job(vehicle_job_id)
      return failed_response("Tripsheet: #{vehicle_job_id} does not exist") unless vehicle_job && vehicle_job[:stock_type_id] == stock_type_id
      return failed_response("Tripsheet: #{vehicle_job_id} already offloaded") if vehicle_job[:offloaded_at]
      return failed_response('Vehicle not loaded') unless vehicle_job[:loaded_at]
      return failed_response('Location does not store bins') unless locn_repo.location_storage_types(location_id).include?(AppConst::STORAGE_TYPE_BINS)
      return failed_response("Incorrect location scanned. Scanned tripsheet is destined for:#{locn_repo.find_location(vehicle_job[:planned_location_to_id])[:location_long_code]}") unless location_id.to_i == vehicle_job[:planned_location_to_id]

      success_response('')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def validate_delivery(id)
      delivery = find_rmt_delivery(id)
      return failed_response("Delivery: #{id} does not exist") unless delivery
      return failed_response("Delivery: #{id} has already been tipped") if delivery[:delivery_tipped]
      return failed_response("Action not allowed - #{id} is an auto bin allocation delivery") if delivery[:bin_scan_mode] == AppConst::AUTO_ALLOCATE_BIN_NUMBERS
      return failed_response("quantity_bins_with_fruit has not yet been set for delivery:#{id}") unless delivery[:quantity_bins_with_fruit]

      return failed_response("All #{delivery[:quantity_bins_with_fruit]} bins have already been received(scanned)")  unless delivery[:quantity_bins_with_fruit] > RawMaterialsApp::RmtDeliveryRepo.new.delivery_bin_count(id)

      ok_response
    end

    def validate_bin_to_offload(id, bin_asset_number)
      bin_id, bin_scrapped = repo.get_value(:rmt_bins, %i[id scrapped], bin_asset_number: bin_asset_number)
      return failed_response("Bin: #{bin_asset_number} does not exist") unless bin_id
      return failed_response("Bin: #{bin_asset_number} has been scrapped") if bin_scrapped

      vju_id, vju_offloaded_at = repo.get_value(:vehicle_job_units, %i[id offloaded_at], stock_item_id: bin_id, vehicle_job_id: id)
      return failed_response("Bin: #{bin_asset_number} is not on tripsheet") unless vju_id
      return failed_response("Bin: #{bin_asset_number} has already been offloaded") if vju_offloaded_at

      success_response('ok', bin_id)
    end

    def offload_bin(vehicle_job_id, bin_id) # rubocop:disable Metrics/AbcSize
      vehicle_job_unit = insp_repo.find_vehicle_job_unit_by_stock_item_and_vehicle_job(bin_id, vehicle_job_id)
      instance = { vehicle_job_offloaded: false, vehicle_job_id: vehicle_job_unit[:vehicle_job_id] }

      repo.transaction do
        unless vehicle_job_unit[:offloaded_at]
          repo.update(:vehicle_job_units, vehicle_job_unit[:id], offloaded_at: Time.now)
          log_status(:rmt_bins, bin_id, AppConst::RMT_BIN_OFFLOADED)
        end

        tripsheet_bins = repo.tripsheet_bins(vehicle_job_id)
        if (tripsheet_bins.all.find_all { |p| !p[:offloaded_at] }).empty?
          location_to_id = complete_bins_offload_vehicle(vehicle_job_id, tripsheet_bins.map { |b| b[:stock_item_id] })
          instance.merge!(vehicle_job_offloaded: true, pallets_moved: tripsheet_bins.count, location: repo.get(:locations, location_to_id, :location_long_code))
        end
      end

      success_response('Bin Offloaded Successfully', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def complete_bins_offload_vehicle(vehicle_job_id, bin_ids)
      repo.update(:vehicle_jobs, vehicle_job_id, offloaded_at: Time.now)
      location_to_id = repo.get(:vehicle_jobs, vehicle_job_id, :planned_location_to_id)
      bin_ids.each do |b|
        res = FinishedGoodsApp::MoveStock.call(AppConst::BIN_STOCK_TYPE, b, location_to_id, AppConst::BIN_OFFLOAD_VEHICLE_MOVE_BIN_BUSINESS_PROCESS, nil)
        raise res.message unless res.success
      end

      rmt_delivery_id = repo.get(:vehicle_jobs, vehicle_job_id, :rmt_delivery_id)
      if rmt_delivery_id
        repo.update(:rmt_deliveries, rmt_delivery_id, tripsheet_offloaded: true, tripsheet_offloaded_at: Time.now)
        log_status(:rmt_deliveries, rmt_delivery_id, AppConst::DELIVERY_TRIPSHEET_OFFLOADED)
      end

      location_to_id
    end

    def update_rmt_bin_asset_level(bin_asset_number, bin_fullness)
      repo.update_rmt_bin_asset_level(bin_asset_number, bin_fullness)
    end

    def create_scanned_bin_groups(id, params) # rubocop:disable Metrics/AbcSize
      params.merge!(qty_bins: 1)

      delivery = find_rmt_delivery(id)
      params = params.merge(get_header_inherited_field(delivery, params[:rmt_container_type_id]))
      res = validate_rmt_bin_params(params)
      return validation_failed_response(res) if res.failure?

      bin_asset_numbers = UtilityFunctions.parse_string_to_array(params.delete(:scan_bin_numbers).gsub(' ', ','))
      bin_asset_numbers.each do |bin_asset_number|
        if RawMaterialsApp::RmtDeliveryRepo.new.find_bin_by_asset_number(bin_asset_number)
          bin_asset_numbers.delete(bin_asset_number)
          return validation_failed_response(OpenStruct.new(messages: { scan_bin_numbers: ["Bin #{bin_asset_number} already exists"] }, scan_bin_numbers: bin_asset_numbers.join("\n")))
        end
      end

      create_bins(params, bin_asset_numbers)
    end

    def create_bin_groups(id, params) # rubocop:disable Metrics/AbcSize
      delivery = find_rmt_delivery(id)
      params = params.merge(get_header_inherited_field(delivery, params[:rmt_container_type_id]))
      res = validate_rmt_bin_params(params)
      return validation_failed_response(res) if res.failure?

      bin_asset_numbers = repo.get_available_bin_asset_numbers(params[:qty_bins_to_create])
      return validation_failed_response(OpenStruct.new(messages: { qty_bins_to_create: ["Couldn't find #{params[:qty_bins_to_create].to_i - bin_asset_numbers.length} available bin_asset_numbers in the system"] })) unless bin_asset_numbers.length == params[:qty_bins_to_create].to_i

      create_bins(params, bin_asset_numbers.map(&:last), bin_asset_numbers.map(&:first))
    end

    def create_bins(params, bin_asset_numbers, bin_asset_number_ids = nil) # rubocop:disable Metrics/AbcSize
      created_bins = []
      repo.transaction do
        params.delete(:qty_bins_to_create)
        params[:location_id] ||= AppConst::CR_RMT.default_delivery_location
        params[:rmt_class_id] = nil if params[:rmt_class_id].nil_or_empty?
        bin_asset_numbers.each do |bin_asset_number|
          params[:bin_asset_number] = bin_asset_number
          bin_id = repo.create_rmt_bin(params)
          log_status(:rmt_bins, bin_id, 'BIN RECEIVED')
          created_bins << rmt_bin(bin_id)
        end
        repo.update(:bin_asset_numbers, bin_asset_number_ids, last_used_at: Time.now) if bin_asset_number_ids
      end

      success_response('Bins Created Successfully', created_bins)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_rebin_groups(production_run_id, params) # rubocop:disable Metrics/AbcSize
      params = params.merge(production_run_rebin_id: production_run_id)

      params = calc_rebin_params(params)

      res = validate_rmt_rebin_params(params)
      return validation_failed_response(res) if res.failure?

      return failed_response('Container Material Type must have a tare_weight') unless repo.get(:rmt_container_material_types, params[:rmt_container_material_type_id], :tare_weight)

      bin_asset_numbers = repo.get_available_bin_asset_numbers(params[:qty_bins_to_create])
      return failed_response("Couldn't find #{params[:qty_bins_to_create]} available bin_asset_numbers in the system") unless bin_asset_numbers.length == params[:qty_bins_to_create].to_i

      created_rebins = []
      repo.transaction do
        params.delete(:qty_bins_to_create)
        bin_asset_numbers.map(&:last).each do |bin_asset_number|
          params[:bin_asset_number] = bin_asset_number
          id = repo.create_rmt_bin(params)
          log_status(:rmt_bins, id, 'REBIN_CREATED')
          created_rebins << rmt_bin(id)
        end
        log_transaction
        repo.update(:bin_asset_numbers, bin_asset_numbers.map(&:first), last_used_at: Time.now)
      end

      success_response('Rebins Created Successfully', created_rebins)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_rebin(params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      bin_asset = repo.get_available_bin_asset_numbers(1)
      bin_asset_id = bin_asset.map(&:last).last
      params[:bin_asset_number] = bin_asset.map(&:last).first
      return failed_response("Couldn't find 1 available bin_asset_numbers in the system") unless params[:bin_asset_number]

      vres = validate_bin_asset_no_format(params)
      return vres unless vres.success
      return failed_response("Scanned Bin Number:#{params[:bin_asset_number]} is already in stock") if AppConst::USE_PERMANENT_RMT_BIN_BARCODES && !bin_asset_number_available?(params[:bin_asset_number])

      params = calc_rebin_params(params)

      res = validate_rmt_rebin_params(params)
      return validation_failed_response(res) if res.failure?

      return failed_response('Container Material Type must have a tare_weight') unless repo.get(:rmt_container_material_types, params[:rmt_container_material_type_id], :tare_weight)

      id = nil
      repo.transaction do
        id = repo.create_rmt_bin(res)
        repo.update(:bin_asset_numbers, bin_asset_id, last_used_at: Time.now)
        log_status(:rmt_bins, id, 'REBIN_CREATED')
        log_transaction
      end
      instance = rmt_bin(id)
      success_response('Created RMT rebin', instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { status: ['This RMT bin already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_rebin(id, params) # rubocop:disable Metrics/AbcSize
      params = calc_edit_rebin_params(params)
      res = validate_update_rmt_rebin_params(params)
      return validation_failed_response(res) if res.failure?

      return failed_response('Container Material Type must have a tare_weight') unless repo.get(:rmt_container_material_types, params[:rmt_container_material_type_id], :tare_weight)

      failed_response('Bum Klaat')

      repo.transaction do
        repo.update_rmt_bin(id, res)
        log_transaction
      end
      instance = rmt_bin(id)
      success_response('Updated RMT rebin', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_rmt_bin(delivery_id, params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity,  Metrics/PerceivedComplexity
      vres = validate_bin_asset_no_format(params)
      return vres unless vres.success
      return failed_response("Scanned Bin Number:#{params[:bin_asset_number]} is already in stock") if AppConst::USE_PERMANENT_RMT_BIN_BARCODES && !bin_asset_number_available?(params[:bin_asset_number])

      delivery = find_rmt_delivery(delivery_id)
      params = params.merge(get_header_inherited_field(delivery, params[:rmt_container_type_id]))
      params[:location_id] ||= AppConst::CR_RMT.default_delivery_location
      res = validate_rmt_bin_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_rmt_bin(res)

        unless params[:gross_weight].nil_or_empty?
          options = { force_find_by_id: false, weighed_manually: true, avg_gross_weight: false }
          bin_number = (AppConst::USE_PERMANENT_RMT_BIN_BARCODES ? res.to_h[:bin_asset_number] : id)
          attrs = { bin_number: bin_number, gross_weight: params[:gross_weight].to_i }
          rw_res = MesscadaApp::UpdateBinWeights.call(attrs, options)
          raise rw_res.message unless rw_res.success
        end

        log_status(:rmt_bins, id, 'BIN RECEIVED')
        log_transaction
      end
      instance = rmt_bin(id)
      success_response('Created RMT bin', instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { status: ['This RMT bin already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def validate_bin_asset_no_format(params)
      return ok_response unless AppConst::USE_PERMANENT_RMT_BIN_BARCODES
      return validation_failed_response(OpenStruct.new(messages: { bin_asset_number: ['is not in a valid format'] })) unless bin_asset_regex_check_ok?(params[:bin_asset_number])

      ok_response
    end

    def validate_bin_asset_numbers_format(params)
      error = {}
      params.find_all { |k, _v| k.to_s.include?('bin_asset_number') }.each do |k, _v|
        error.store(k, ['is not in a valid format']) unless bin_asset_regex_check_ok?(params[k])
      end
      error
    end

    def bin_asset_regex_check_ok?(bin_asset_number)
      Array(AppConst::BIN_ASSET_REGEX.split(',')).any? do |regex|
        Regexp.new(regex).match?(bin_asset_number)
      end
    end

    def validate_bin_asset_numbers_duplicate_scans(params)
      error = {}
      scans = params.find_all { |k, _v| k.to_s.include?('bin_asset_number') }.map { |b| b[1] }
      duplicate_scans = scans.find_all { |v| scans.count(v) > 1 }
      params.find_all { |_k, v| duplicate_scans.include?(v) }.each do |k, _v|
        error.store(k, ["Bin #{params[k]} scanned more than once"])
      end
      error
    end

    def validate_bins_exist(params)
      error = {}
      scans = params.find_all { |k, _v| k.to_s.include?('bin_asset_number') }.map { |b| b[1] }
      existing_bins = repo.select_values(:rmt_bins, :bin_asset_number, bin_asset_number: scans)
      params.find_all { |_k, v| (scans - existing_bins).include?(v) }.each do |k, _v|
        error.store(k, ['Bin does not exist'])
      end
      error
    end

    def create_rmt_bins(delivery_id, params) # rubocop:disable Metrics/AbcSize
      res = validate_bin_asset_numbers_duplicate_scans(params)
      return validation_failed_response(OpenStruct.new(message: 'Validation Error', messages: res)) unless res.empty?

      res = validate_bin_asset_numbers_format(params)
      return validation_failed_response(OpenStruct.new(message: 'Validation Error', messages: res)) unless res.empty?

      res = validate_bins_in_stock(params)
      return validation_failed_response(OpenStruct.new(message: 'Validation Error', messages: res)) unless res.empty?

      delivery = find_rmt_delivery(delivery_id)
      params = params.merge(get_header_inherited_field(delivery, params[:rmt_container_type_id]))

      submitted_bins = params.find_all { |k, _v| k.to_s.include?('bin_asset_number') }.map { |_k, v| v }
      params.delete_if { |k, _v| k.to_s.include?('bin_asset_number') }
      params[:location_id] ||= AppConst::CR_RMT.default_delivery_location

      res = validate_rmt_bin_params(params)
      return failed_response(unwrap_failed_response(validation_failed_response(res))) if res.failure?

      repo.transaction do
        submitted_bins.each do |bin_asset_number|
          bin_params = { bin_asset_number: bin_asset_number }.merge(params)
          id = repo.create_rmt_bin(bin_params)
          log_status(:rmt_bins, id, 'BIN RECEIVED')
        end

        log_status(:rmt_deliveries, delivery_id, 'DELIVERY RECEIVED')
        log_transaction
      end
      success_response('Bins Scanned Successfully',
                       delivery)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_bins_for_kr(missing_bins)
      missing_bins.each do |b|
        res = MesscadaApp::BinIntegration.new(b, nil).bin_attributes
        return res unless res.success

        res.instance[:bin_attrs].delete_if { |k, _v| [:commodity_id].include?(k) }
        id = RawMaterialsApp::RmtDeliveryRepo.new.create_rmt_bin(res.instance[:bin_attrs])
        repo.log_status(:rmt_bins, id, 'BIN CREATED FROM EXTERNAL SYSTEM')
      end

      ok_response
    end

    def validate_bins_already_converted(params)
      error = {}
      scans = params.find_all { |k, _v| k.to_s.include?('bin_asset_number') }.map { |b| b[1] }
      bins_already_converted = repo.find_pallet_sequences_for_by_bin_assets(scans)
      params.find_all { |_k, v| bins_already_converted.include?(v) }.each do |k, _v|
        error.store(k, ['Bin has already been converted'])
      end
      error
    end

    def convert_bins_to_pallets(params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      params.delete_if { |k, v| v.nil_or_empty? || k.to_s.include?('scan_field') }
      res = validate_bin_asset_numbers_duplicate_scans(params)
      return validation_failed_response(OpenStruct.new(message: 'Validation Error', messages: res)) unless res.empty?

      repo.transaction do
        unless (errors = validate_bins_exist(params)).empty?
          return validation_failed_response(OpenStruct.new(message: 'Validation Error', messages: errors)) unless AppConst::CLIENT_CODE == 'kr'

          res = create_bins_for_kr(params.find_all { |k, _v| errors.keys.include?(k) }.map { |b| b[1] })
          raise res.message unless res.success
        end

        res = validate_bins_already_converted(params)
        return validation_failed_response(OpenStruct.new(message: 'Validation Error', messages: res)) unless res.empty?

        bins = []
        bins << 1 if params.key?(:bin_asset_number1)
        bins << 2 if params.key?(:bin_asset_number2)
        bins << 3 if params.key?(:bin_asset_number3)
        success_response('ok', bins: bins)
      end
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def create_pallet_from_bins(pallet_format_id, bins_info)
      RawMaterialsApp::CreatePalletInfoFromBins.call(@user.user_name, pallet_format_id, bins_info)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def validate_bins_in_stock(params)
      error = {}
      params.find_all { |k, _v| k.to_s.include?('bin_asset_number') }.each do |k, _v|
        error.store(k, ["Bin #{params[k]} already in stock"]) if !params[k].nil_or_empty? && !bin_asset_number_available?(params[k])
      end
      error
    end

    def bin_asset_number_available?(bin_asset_number)
      repo.bin_asset_number_available?(bin_asset_number)
    end

    def get_run_inherited_fields(run)
      { orchard_id: run.orchard_id,
        cultivar_id: run.cultivar_id,
        season_id: run.season_id,
        farm_id: run.farm_id,
        puc_id: run.puc_id }
    end

    def get_header_inherited_field(delivery, container_type_id)
      rmt_inner_container_type_id = repo.rmt_container_type_rmt_inner_container_type(container_type_id) unless container_type_id.nil_or_empty?
      { rmt_delivery_id: delivery.id,
        orchard_id: delivery.orchard_id,
        cultivar_id: delivery.cultivar_id,
        season_id: delivery.season_id,
        bin_received_date_time: Time.now.to_s,
        farm_id: delivery.farm_id,
        puc_id: delivery.puc_id,
        rmt_inner_container_type_id: rmt_inner_container_type_id }
    end

    def pdt_update_rmt_bin(id, params)
      res = update_rmt_bin(id, params)
      log_status(:rmt_bins, res.instance[:id], 'BIN PDT EDIT') if res.success
      res
    end

    def update_rmt_bin(id, params) # rubocop:disable Metrics/AbcSize
      delivery = find_rmt_delivery_by_bin_id(id)
      submitted_bin_received_date_time = params[:bin_received_date_time]
      params = params.merge(get_header_inherited_field(delivery, params[:rmt_container_type_id]))
      params[:bin_received_date_time] = submitted_bin_received_date_time if submitted_bin_received_date_time
      res = validate_rmt_bin_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_rmt_bin(id, res)
        log_transaction
      end
      instance = rmt_bin(id)
      success_response('Updated RMT bin', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_rmt_bin(id)
      repo.transaction do
        repo.delete_rmt_bin(id)
        log_status(:rmt_bins, id, 'DELETED')
        log_transaction
      end
      success_response('Deleted RMT bin')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def validate_bin(bin_number)
      bin = find_rmt_bin_by_id_or_asset_number(bin_number)
      return failed_response("Scanned Bin:#{bin_number} is not in stock") unless bin
      return failed_response("Scanned Bin:#{bin_number} has been tipped") if bin[:bin_tipped]

      success_response('Valid Bin Scanned',
                       bin)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def validate_rebin(bin_number)
      bin = find_rmt_bin_by_id_or_asset_number(bin_number)
      return failed_response("Scanned Bin:#{bin_number} is not in stock") unless bin
      return failed_response("Bin Scanned:#{bin_number}. Please scan a rebin instead") unless bin[:production_run_rebin_id]
      return failed_response("Scanned Bin:#{bin_number} has been tipped") if bin[:bin_tipped]

      success_response('Valid Bin Scanned',
                       bin)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def move_bin(bin_number, location_id, location_scan_field) # rubocop:disable Metrics/AbcSize
      location_id = MasterfilesApp::LocationRepo.new.resolve_location_id_from_scan(location_id, location_scan_field)
      return failed_response('Location does not exist') unless !location_id.nil_or_empty? && repo.exists?(:locations, id: location_id)

      bin = repo.find_rmt_bin(bin_number)
      return failed_response('Bin is already at this location') unless bin[:location_id] != location_id

      repo.transaction do
        FinishedGoodsApp::MoveStock.call(AppConst::BIN_STOCK_TYPE, bin_number, location_id, 'MOVE_BIN', nil)
      end
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def find_rmt_bin_by_id_or_asset_number(bin_number)
      return repo.find_bin_by_asset_number(bin_number) if AppConst::USE_PERMANENT_RMT_BIN_BARCODES

      repo.find_rmt_bin_stock(bin_number)
    end

    def find_container_material_owners_by_container_material_type(container_material_type_id)
      repo.find_container_material_owners_by_container_material_type(container_material_type_id)
    end

    def find_rmt_delivery(id)
      repo.find_rmt_delivery(id)
    end

    def get_delivery_confirmation_details(id)
      repo.delivery_confirmation_details(id)
    end

    def bin_details(id)
      repo.bin_details(id)
    end

    def rebin_details(id)
      repo.rebin_details(id)
    end

    def find_rmt_delivery_by_bin_id(id)
      repo.find_rmt_delivery_by_bin_id(id)
    end

    def find_current_delivery
      repo.find_current_delivery
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::RmtBin.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def get_bin_label_data(bin_id)
      repo.find_bin_label_data(bin_id)
    end

    def print_bin_barcode(id, params)
      instance = get_bin_label_data(id)
      LabelPrintingApp::PrintLabel.call(AppConst::LABEL_BIN_BARCODE, instance, params)
    end

    def preprint_bin_barcodes(bin_asset_numbers, params) # rubocop:disable Metrics/AbcSize
      label_name = params[:bin_label]
      print_params = { no_of_prints: 1, printer: params[:printer] }
      res = nil
      bin_asset_numbers.map { |b| b[1] }.each do |bin_asset_number|
        instance = { farm_code: !params[:farm_id].nil_or_empty? ? repo.get(:farms, params[:farm_id], :farm_code) : nil,
                     puc_code: !params[:puc_id].nil_or_empty? ? repo.get(:pucs, params[:puc_id], :puc_code) : nil,
                     orchard_code: !params[:orchard_id].nil_or_empty? ? repo.get(:orchards, params[:orchard_id], :orchard_code) : nil,
                     cultivar_name: !params[:cultivar_id].nil_or_empty? ? repo.get(:cultivars, params[:cultivar_id], :cultivar_name) : nil,
                     bin_asset_number: bin_asset_number }
        res = LabelPrintingApp::PrintLabel.call(label_name, instance, print_params)
        return res unless res.success
      end

      repo.update(:bin_asset_numbers, bin_asset_numbers.map { |b| b[0] }, last_used_at: Time.now)
      success_response('Labels Printed Successfully', bin_asset_numbers.map { |b| b[1] }.join(','))
    end

    def print_rebin_barcodes(id, params)
      label_name = params[:rebin_label]
      print_params = { no_of_prints: params[:qty_to_print], printer: params[:printer] }

      instance = repo.rebin_label_printing_instance(id)
      LabelPrintingApp::PrintLabel.call(label_name, instance, print_params)
    end

    def pre_print_bin_labels(params)
      res = validate_bin_label_params(params)
      return validation_failed_response(res) if res.failure?

      bin_asset_numbers = repo.get_available_bin_asset_numbers(params[:no_of_prints])
      return failed_response("Couldn't find #{params[:no_of_prints]} available bin_asset_numbers in the system") unless bin_asset_numbers.length == params[:no_of_prints].to_i

      preprint_bin_barcodes(bin_asset_numbers, params)
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def print_rebin_labels(id, params)
      res = validate_rebin_label_params(params)
      return validation_failed_response(res) if res.failure?

      print_rebin_barcodes(id, params)
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_bin_labels(params)
      repo.transaction do
        bin_asset_numbers = params[:bin_asset_numbers].split(',')
        bin_asset_numbers.each do |bin_asset_number|
          params[:bin_asset_number] = bin_asset_number
          params.delete_if { |k, v| %i[no_of_prints printer bin_label bin_asset_numbers].include?(k) || v.nil_or_empty? }
          repo.create_rmt_bin_label(params)
        end
      end
      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def stepper(step_key)
      @stepper ||= RmtBinStep.new(step_key, @user, @context.request_ip)
    end

    def check(task, id = nil)
      TaskPermissionCheck::RmtBin.call(task, id)
    end

    def find_vehicle_stock_type(id)
      messcada_repo.find_vehicle_stock_type(id)
    end

    def tripsheet_bins(id)
      repo.tripsheet_bins(id)
    end

    def loaded_and_offloaded_bins(id)
      repo.tripsheet_bins(id).partition { |p| p[:offloaded_at].nil? }
    end

    def default_printer_for_application(application)
      printer_repo.default_printer_for_application(application)
    end

    def find_printer(id)
      printer_repo.find_printer(id)
    end

    def find_locations_by_location_type_and_storage_type(location_type_code, storage_type_code)
      locn_repo.find_locations_by_location_type_and_storage_type(location_type_code, storage_type_code)
    end

    def get_vehicle_job_location(vehicle_job_id)
      insp_repo.get_vehicle_job_location(vehicle_job_id)
    end

    def find_rmt_bin_flat(id)
      repo.find_rmt_bin_flat(id)
    end

    def validate_location(scanned_location, location_scan_field)
      location_id = locn_repo.resolve_location_id_from_scan(scanned_location, location_scan_field)
      return validation_failed_response(messages: { location: ['Location does not exist'] }) if location_id.nil_or_empty?

      success_response('ok', location_id)
    end

    def location_short_code_for(location_id)
      repo.get(:locations, location_id, :location_short_code)
    end

    def move_location_bin(bin_number, location_id) # rubocop:disable Metrics/AbcSize
      bin = repo.find_rmt_bin(bin_number)
      return failed_response('Bin is already at this location') if bin[:location_id] == location_id

      repo.transaction do
        FinishedGoodsApp::MoveStock.call(AppConst::BIN_STOCK_TYPE, bin_number, location_id, 'MOVE_BIN', nil)
      end
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message("#{__method__} #{bin_number}, Loc: #{location}"))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def rmt_bin_attrs_for_display(rmt_bin_id)
      bin = repo.find_rmt_bin_flat(rmt_bin_id).to_h
      bin[:bin_load_id] = repo.get(:bin_load_products, bin[:bin_load_product_id], :bin_load_id)
      bin[:material_owner] = repo.container_material_owner_for(bin[:rmt_material_owner_party_role_id], bin[:rmt_container_material_type_id])
      bin[:presort_unit] = repo.presort_unit_for(bin[:presort_staging_run_child_id])
      bin
    end

    private

    def calc_rebin_params(params) # rubocop:disable Metrics/AbcSize
      default_rmt_container_type = RawMaterialsApp::RmtDeliveryRepo.new.rmt_container_type_by_container_type_code(AppConst::DEFAULT_RMT_CONTAINER_TYPE)
      if default_rmt_container_type
        params[:rmt_container_type_id] = default_rmt_container_type[:id]
        params[:rmt_inner_container_type_id] = default_rmt_container_type[:rmt_inner_container_type_id]
      end
      params[:qty_bins] = 1
      params[:qty_inner_bins] = 1 if AppConst::DELIVERY_CAPTURE_INNER_BINS
      params[:rebin_created_at] = Time.now
      params[:is_rebin] = true

      production_run = repo.find(:production_runs, ProductionApp::ProductionRun, params[:production_run_rebin_id])
      params = params.merge(get_run_inherited_fields(production_run))

      unless params[:rmt_container_material_type_id].nil_or_empty?
        tare_weight = repo.get_rmt_bin_tare_weight(params)
        params[:nett_weight] = (params[:gross_weight].to_i - tare_weight) if tare_weight
      end

      location_id = repo.get_run_packhouse_location(params[:production_run_rebin_id])
      params = params.merge(location_id: location_id)

      params
    end

    def calc_edit_rebin_params(params) # rubocop:disable Metrics/AbcSize
      production_run = repo.find(:production_runs, ProductionApp::ProductionRun, params[:production_run_rebin_id])
      params = params.merge(get_run_inherited_fields(production_run))

      unless params[:rmt_container_material_type_id].nil_or_empty?
        tare_weight = repo.get_rmt_bin_tare_weight(params)
        params[:nett_weight] = (params[:gross_weight].to_i - tare_weight) if tare_weight
      end

      location_id = repo.get_run_packhouse_location(params[:production_run_rebin_id])
      params = params.merge(location_id: location_id)

      params
    end

    def repo
      @repo ||= RmtDeliveryRepo.new
    end

    def printer_repo
      LabelApp::PrinterRepo.new
    end

    def rmt_bin(id)
      repo.find_rmt_bin_flat(id)
    end

    def validate_rmt_bin_params(params)
      RmtBinSchema.call(params)
    end

    def validate_rmt_rebin_params(params)
      RmtRebinBinSchema.call(params)
    end

    def validate_update_rmt_rebin_params(params)
      UpdateRmtRebinBinSchema.call(params)
    end

    def validate_preprinting_input(params)
      PreprintScreenInput.call(params)
    end

    def validate_bin_label_params(params)
      BinLabelSchema.call(params)
    end

    def validate_tripsheet_params(params)
      FinishedGoodsApp::TripsheetSchema.call(params)
    end

    def validate_rebin_label_params(params)
      RebinLabelSchema.call(params)
    end

    def insp_repo
      @insp_repo ||= FinishedGoodsApp::GovtInspectionRepo.new
    end

    def locn_repo
      MasterfilesApp::LocationRepo.new
    end

    def messcada_repo
      MesscadaApp::MesscadaRepo.new
    end

    def validate_vehicle_job_unit_params(params)
      FinishedGoodsApp::VehicleJobUnitSchema.call(params)
    end
  end
end
