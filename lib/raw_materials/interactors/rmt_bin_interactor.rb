# frozen_string_literal: true

module RawMaterialsApp
  class RmtBinInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def validate_delivery(id) # rubocop:disable Metrics/AbcSize
      delivery = find_rmt_delivery(id)
      return failed_response("Delivery: #{id} does not exist") unless delivery
      return failed_response("Delivery: #{id} has already been tipped") if delivery[:delivery_tipped]
      return failed_response("Action not allowed - #{id} is an auto bin allocation delivery") if delivery[:auto_allocate_asset_number]
      return failed_response("quantity_bins_with_fruit has not yet been set for delivery:#{id}") unless delivery[:quantity_bins_with_fruit]

      return failed_response("All #{delivery[:quantity_bins_with_fruit]} bins have already been received(scanned)")  unless delivery[:quantity_bins_with_fruit] > RawMaterialsApp::RmtDeliveryRepo.new.delivery_bin_count(id)

      ok_response
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
        params[:location_id] = default_location_id unless params[:location_id]
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
          log_transaction
          created_rebins << rmt_bin(id)
        end
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
      params = params.merge(location_id: default_location_id) unless params[:location_id]
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

    def create_rmt_bins(delivery_id, params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
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
      params = params.merge(location_id: default_location_id) unless params[:location_id]

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
      return failed_response("Rebin Scanned:#{bin_number}. Please scan a bin instead") if bin[:production_run_rebin_id]
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
        FinishedGoodsApp::MoveStockService.new(AppConst::BIN_STOCK_TYPE, bin_number, location_id, 'MOVE_BIN', nil).call
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

    def pre_print_bin_labels(params) # rubocop:disable Metrics/AbcSize
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

    def create_bin_labels(params) # rubocop:disable Metrics/AbcSize
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

    private

    def calc_rebin_params(params) # rubocop:disable Metrics/AbcSize
      default_rmt_container_type = RawMaterialsApp::RmtDeliveryRepo.new.rmt_container_type_by_container_type_code(AppConst::DELIVERY_DEFAULT_RMT_CONTAINER_TYPE)
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

    def default_location_id
      return nil unless AppConst::DEFAULT_DELIVERY_LOCATION

      repo.get_id(:locations, location_long_code: AppConst::DEFAULT_DELIVERY_LOCATION)
    end

    def repo
      @repo ||= RmtDeliveryRepo.new
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

    def validate_rebin_label_params(params)
      RebinLabelSchema.call(params)
    end
  end
end
