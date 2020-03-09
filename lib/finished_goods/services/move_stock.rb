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

    def call # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      res = validate
      return res unless res.success

      location_to = MasterfilesApp::LocationRepo.new.lookup_location(location_to_id)

      if location_to[:location_type_code] == 'COLD_BAY_DECK'
        res = find_next_available_deck_position(location_to[:location_short_code])
        return res unless res.success
      end

      upd = { location_id: location_to_id }
      upd.store(:first_cold_storage_at, Time.now) if stock_type.to_s.upcase == 'PALLET' && location_to[:assignment_code] == 'COLD_STORAGE' && !stock_item.first_cold_storage_at

      repo.update_stock_item(stock_item_id, upd, stock_type)

      repo.create_serialized_stock_movement_log(location_from_id: location_from_id, location_to_id: location_to_id, stock_item_id: stock_item_id, stock_item_number: stock_item_number, business_process_id: business_process_id, business_process_object_id: business_process_context_id, serialized_stock_type_id: stock_type_id)
      log_stock_item_status(stock_type)
      success_response("#{stock_type} moved successfully")
    end

    private

    def find_next_available_deck_position(location_code) # rubocop:disable Metrics/AbcSize
      positions = MasterfilesApp::LocationRepo.new.find_filled_deck_positions(location_to_id)

      return failed_response("Deck:#{location_code} is full") if positions.length == 10

      unless (last_pos = positions.map { |l| l.sub("#{location_code}_P", '').to_i }.min)
        last_pos = 11
      end
      deck_position = MasterfilesApp::LocationRepo.new.find_location_by_location_short_code("#{location_code}_P#{last_pos - 1}")
      @location_to_id = deck_position.id

      ok_response
    end

    def log_stock_item_status(stock_type)
      return repo.log_status('pallets', stock_item[:id], AppConst::PALLET_MOVED) if stock_type == 'PALLET'

      repo.log_status('rmt_bins', stock_item[:id], AppConst::RMT_BIN_MOVED)
    end

    def validate
      return validation_failed_response(messages: { location: ['Location does not exist'] }) unless valid_location?

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
      return failed_response("Stock Type: \"#{stock_type}\" does not exist") unless stock_type_rec

      @stock_type_id = stock_type_rec[:id]

      success_response('ok')
    end

    def validate_business_process
      if business_process
        process = repo.find_business_process(business_process)
        return failed_response("Business Process \"#{business_process}\"does not exist") unless process

        @business_process_id = process[:id]
      end

      success_response('ok')
    end

    def validate_stock_item # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      @stock_item = repo.find_stock_item(stock_item_id, stock_type.to_s.upcase)

      return failed_response("#{stock_type} does not exist") unless @stock_item
      return failed_response("#{stock_type} has been scrapped") if @stock_item[:scrapped]
      return failed_response("#{stock_type} has been shipped") if @stock_item[:shipped]
      return failed_response("#{stock_type} has been tipped") if stock_type.to_s.upcase == 'BIN' && @stock_item[:bin_tipped]
      return failed_response("#{stock_type} is already in this location") if @stock_item[:location_id].to_i == location_to_id.to_i

      @location_from_id = @stock_item[:location_id]
      @stock_item_number = stock_type.to_s.upcase == 'PALLET' ? @stock_item.pallet_number : @stock_item[:id]

      success_response('ok')
    end

    def repo
      @repo ||= MesscadaApp::MesscadaRepo.new
    end
  end
end
