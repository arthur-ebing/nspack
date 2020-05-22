# frozen_string_literal: true

module FinishedGoodsApp
  class MoveStockService < BaseService # rubocop:disable Metrics/ClassLength
    attr_reader :stock_type, :stock_item, :stock_item_id, :location_to_id, :business_process, :business_process_context_id, :location_from_id, :stock_item_number, :business_process_id, :stock_type_id

    def initialize(stock_type, stock_item_id, location_to_id, business_process = nil, business_process_context_id = nil)
      @stock_type = stock_type
      @stock_item_id = stock_item_id
      @location_to_id = location_to_id
      @business_process = business_process
      @business_process_context_id = business_process_context_id
    end

    def call # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      res = validate
      return res unless res.success

      location_to = locn_repo.find_location(location_to_id)

      if stock_type == AppConst::PALLET_STOCK_TYPE && location_to[:assignment_code] == 'COLD_STORAGE'
        res = validate_pallet_in_stock
        return res unless res.success
      end

      if stock_type == AppConst::PALLET_STOCK_TYPE && AppConst::CALCULATE_PALLET_DECK_POSITIONS && location_to[:location_type_code] == AppConst::LOCATION_TYPES_COLD_BAY_DECK
        return failed_response("Pallet is already been scanned into deck: #{location_to[:location_long_code]}") if pallet_already_in_deck?

        res = validate_pallet_infront_if_in_deck?
        return res unless res.success

        res = find_next_available_deck_position(location_to[:location_long_code])
        return res unless res.success
      end

      upd = { location_id: location_to_id }
      upd.store(:first_cold_storage_at, Time.now) if stock_type == AppConst::PALLET_STOCK_TYPE && location_to[:assignment_code] == 'COLD_STORAGE' && !stock_item.first_cold_storage_at

      repo.update_stock_item(stock_item_id, upd, stock_type)

      repo.create_serialized_stock_movement_log(location_from_id: location_from_id, location_to_id: location_to_id, stock_item_id: stock_item_id, stock_item_number: stock_item_number, business_process_id: business_process_id, business_process_object_id: business_process_context_id, serialized_stock_type_id: stock_type_id)
      log_stock_item_status(stock_type)
      success_response("#{stock_type}: #{stock_item_number} moved successfully")
    end

    private

    def validate_pallet_in_stock
      return failed_response('Pallet cannot be moved into COLD_STORE, it is not in stock') unless stock_item.in_stock

      success_response('ok')
    end

    def validate_pallet_infront_if_in_deck? # rubocop:disable Metrics/AbcSize
      deck_id = locn_repo.get_parent_location(stock_item.location_id)
      if deck_id && (location_from = locn_repo.find_location(deck_id)) && location_from[:location_type_code] == AppConst::LOCATION_TYPES_COLD_BAY_DECK
        deck_pallets = locn_repo.get_deck_pallets(deck_id)
        plt_pos = deck_pallets.find { |p| p[:pallet_number] == stock_item[:pallet_number] }
        unless (pallets_infront = deck_pallets.find_all { |d| d[:pos] < plt_pos[:pos] && d[:pallet_number] }).empty?
          return failed_response("There are pallets in front of: #{stock_item[:pallet_number]} in the deck.<br> Please move them out of the deck before you can move this pallet.<br><br> #{pallets_infront.map { |p| " #{p[:pallet_number]}(P#{p[:pos]})" }.join(',')}.")
        end
      end

      ok_response
    end

    def pallet_already_in_deck?
      (parent = locn_repo.get_parent_location(location_from_id)) && parent == location_to_id ? true : false
    end

    def find_next_available_deck_position(location_code) # rubocop:disable Metrics/AbcSize
      positions = locn_repo.find_filled_deck_positions(location_to_id)

      return failed_response("Deck:#{location_code} is full") if positions.length == locn_repo.find_max_position_for_deck_location(location_to_id)

      unless (last_pos = positions.min)
        last_pos = locn_repo.find_max_position_for_deck_location(location_to_id) + 1
      end

      if last_pos == 1
        deck_pallets = locn_repo.get_deck_pallets(location_to_id)
        empty_pos = deck_pallets.find_all { |d| d[:pallet_number].nil_or_empty? }.last
        return failed_response("You are trying to move pallet:#{@stock_item_number}<br> into: #{location_code}_P#{empty_pos[:pos]}<br> but there are pallets in front of this position in the deck")
      end
      next_availaible_position = locn_repo.find_location_by_location_long_code("#{location_code}_P#{last_pos - 1}")
      @location_to_id = next_availaible_position.id

      ok_response
    end

    def log_stock_item_status(stock_type)
      return repo.log_status(:pallets, stock_item[:id], AppConst::PALLET_MOVED) if stock_type == 'PALLET'

      repo.log_status(:rmt_bins, stock_item[:id], AppConst::RMT_BIN_MOVED)
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
      @stock_item = repo.find_stock_item(stock_item_id, stock_type)

      return failed_response("#{stock_type} does not exist") unless @stock_item
      return failed_response("#{stock_type} has been scrapped") if @stock_item[:scrapped]

      unless business_process == AppConst::REWORKS_MOVE_BIN_BUSINESS_PROCESS
        return failed_response("#{stock_type} has been shipped") if @stock_item[:shipped]
        return failed_response("#{stock_type} has been tipped") if stock_type == AppConst::BIN_STOCK_TYPE && @stock_item[:bin_tipped]
        return failed_response("#{stock_type} is already in this location") if @stock_item[:location_id].to_i == location_to_id.to_i
      end

      return failed_response("#{stock_type} current location has not been set") unless @stock_item[:location_id]

      @location_from_id = @stock_item[:location_id]
      @stock_item_number = stock_type == AppConst::PALLET_STOCK_TYPE ? @stock_item.pallet_number : @stock_item[:id]

      success_response('ok')
    end

    def repo
      @repo ||= MesscadaApp::MesscadaRepo.new
    end

    def locn_repo
      MasterfilesApp::LocationRepo.new
    end
  end
end
