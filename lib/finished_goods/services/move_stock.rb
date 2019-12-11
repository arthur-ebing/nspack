# frozen_string_literal: true

module FinishedGoodsApp
  class MoveStockService < BaseService
    attr_reader :stock_type, :stock_item, :stock_item_id, :location_to_id, :business_process, :business_process_context_id, :location_from_id, :stock_item_number, :business_process_id, :stock_type_id

    def initialize(stock_type, stock_item_id, location_to_id, business_process = nil, business_process_context_id = nil)
      @stock_type = stock_type
      @stock_item_id = stock_item_id
      @location_to_id = location_to_id
      @business_process = business_process
      @business_process_context_id = business_process_context_id
    end

    def call # rubocop:disable Metrics/AbcSize
      res = validate
      return res unless res.success

      location_to = MasterfilesApp::LocationRepo.new.find_location(location_to_id)
      upd = { location_id: location_to_id }
      upd.store(:first_cold_storage_at, Time.now) if location_to.assignment_code == 'COLD_STORAGE' && !stock_item.first_cold_storage_at
      repo.update_pallet(stock_item_id, upd)

      repo.create_serialized_stock_movement_log(location_from_id: location_from_id, location_to_id: location_to_id, stock_item_id: stock_item_id, stock_item_number: stock_item_number, business_process_id: business_process_id, business_process_object_id: business_process_context_id, serialized_stock_type_id: stock_type_id)
      repo.log_status('pallets', stock_item.id, AppConst::PALLET_MOVED) if stock_type.to_s.upcase == 'PALLET'
      success_response('Pallet moved successfully')
    end

    private

    def validate
      return failed_response('Location does not exist') unless valid_location?

      res = validate_stock_type
      return res unless res.success

      res = validate_business_process
      return res unless res.success

      res = validate_stock_item
      return res unless res.success

      success_response('ok')
    end

    def valid_location?
      repo.exists?(:locations, id: location_to_id)
    end

    def validate_stock_type
      stock_type_rec = repo.find_stock_type(stock_type)
      return failed_response("Stock Type: #{stock_type} does not exist") unless stock_type_rec

      @stock_type_id = stock_type_rec[:id]

      success_response('ok')
    end

    def validate_business_process
      if business_process
        process = repo.find_business_process(business_process)
        return failed_response('Location does not exist') unless process

        @business_process_id = process[:id]
      end

      success_response('ok')
    end

    def validate_stock_item # rubocop:disable Metrics/AbcSize
      if stock_type.to_s.upcase == 'PALLET'
        @stock_item = repo.find_pallet(stock_item_id)

        return failed_response('Pallet does not exist') unless @stock_item
        return failed_response('Pallet has been scrapped') if @stock_item.scrapped
        return failed_response('Pallet has been shipped') if @stock_item.shipped
        return failed_response('Pallet is already in this location') if @stock_item.location_id == location_to_id

        @location_from_id = @stock_item.location_id
        @stock_item_number = @stock_item.pallet_number
      end
      success_response('ok')
    end

    def repo
      @repo ||= MesscadaApp::MesscadaRepo.new
    end
  end
end
