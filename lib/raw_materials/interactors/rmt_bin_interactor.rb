# frozen_string_literal: true

module RawMaterialsApp
  class RmtBinInteractor < BaseInteractor # rubocop:disable ClassLength
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

    def create_bin_groups(id, params) # rubocop:disable Metrics/AbcSize
      delivery = find_rmt_delivery(id)
      params = params.merge(get_header_inherited_field(delivery, params[:rmt_container_type_id]))
      res = validate_rmt_bin_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      bin_asset_numbers = repo.get_available_bin_asset_numbers(params[:qty_bins_to_create])
      return failed_response("Couldn't find #{params[:qty_bins_to_create]} available bin_asset_numbers in the system") unless bin_asset_numbers.length == params[:qty_bins_to_create].to_i

      created_bins = []
      repo.transaction do
        params.delete(:qty_bins_to_create)
        bin_asset_numbers.map { |a| a[0] }.each do |bin_asset_number|
          params[:bin_asset_number] = bin_asset_number
          bin_id = repo.create_rmt_bin(params)
          log_status('rmt_bins', bin_id, 'BIN_RECEIVED')
          created_bins << rmt_bin(bin_id)
        end
        repo.update(:bin_asset_numbers, bin_asset_numbers.map { |a| a[1] }, last_used_at: Time.now)
      end

      success_response('Bins Created Successfully', created_bins)
    end

    def create_rmt_bin(delivery_id, params) # rubocop:disable Metrics/AbcSize
      vres = validate_bin_asset_no_format(params)
      return vres unless vres.success
      return failed_response("Scanned Bin Number:#{params[:bin_asset_number]} is already in stock") if AppConst::USE_PERMANENT_RMT_BIN_BARCODES && !bin_asset_number_available?(params[:bin_asset_number])

      delivery = find_rmt_delivery(delivery_id)
      params = params.merge(get_header_inherited_field(delivery, params[:rmt_container_type_id]))
      res = validate_rmt_bin_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_rmt_bin(res)
        log_status('rmt_bins', id, 'BIN_RECEIVED')
        log_transaction
      end
      instance = rmt_bin(id)
      success_response('Created rmt bin',
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { status: ['This rmt bin already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def validate_bin_asset_no_format(params)
      return ok_response unless AppConst::USE_PERMANENT_RMT_BIN_BARCODES
      return validation_failed_response(OpenStruct.new(messages: { bin_asset_number: ['is not in the correct format'] })) unless AppConst::BIN_ASSET_REGEX.match?(params[:bin_asset_number])

      ok_response
    end

    def validate_bin_asset_numbers_format(params)
      error = {}
      params.find_all { |k, _v| k.to_s.include?('bin_asset_number') }.each do |k, _v|
        error.store(k, ['is not in the correct format']) unless AppConst::BIN_ASSET_REGEX.match?(params[k])
      end
      error
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

      res = validate_rmt_bin_params(params)
      return failed_response(unwrap_failed_response(validation_failed_response(res))) unless res.messages.empty?

      repo.transaction do
        submitted_bins.each do |bin_asset_number|
          bin_params = { bin_asset_number: bin_asset_number }.merge(params)
          id = repo.create_rmt_bin(bin_params)
          log_status('rmt_bins', id, 'BIN_RECEIVED')
        end

        log_status('rmt_deliveries', delivery_id, 'DELIVERY_RECEIVED')
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
      log_status('rmt_bins', res.instance[:id], 'BIN_PDT_EDIT') if res.success
      res
    end

    def update_rmt_bin(id, params) # rubocop:disable Metrics/AbcSize
      delivery = find_rmt_delivery_by_bin_id(id)
      params = params.merge(get_header_inherited_field(delivery, params[:rmt_container_type_id]))
      res = validate_rmt_bin_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_rmt_bin(id, res)
        log_transaction
      end
      instance = rmt_bin(id)
      success_response('Updated rmt bin',
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_rmt_bin(id)
      repo.transaction do
        repo.delete_rmt_bin(id)
        log_status('rmt_bins', id, 'DELETED')
        log_transaction
      end
      success_response('Deleted rmt bin')
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

    def move_bin(bin_number, location_id, is_scanned_location) # rubocop:disable Metrics/AbcSize
      location_id = FinishedGoodsApp::LoadRepo.new.get_location_id_by_barcode(location_id) unless is_scanned_location
      return failed_response('Location does not exist') unless !location_id.nil_or_empty? && repo.exists?(:locations, id: location_id)

      bin = repo.find_rmt_bin(bin_number)
      return failed_response('Bin is already at this location') unless bin[:location_id] != location_id

      repo.transaction do
        FinishedGoodsApp::MoveStockService.new('BIN', bin_number, location_id, 'MOVE_BIN', nil).call
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
      repo.find(:rmt_deliveries, RawMaterialsApp::RmtDelivery, id)
    end

    def get_delivery_confirmation_details(id)
      repo.delivery_confirmation_details(id)
    end

    def bin_details(id)
      repo.bin_details(id)
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

    private

    def repo
      @repo ||= RmtDeliveryRepo.new
    end

    def rmt_bin(id)
      repo.find_rmt_bin_flat(id)
    end

    def validate_rmt_bin_params(params)
      RmtBinSchema.call(params)
    end
  end
end
