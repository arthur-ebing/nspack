# frozen_string_literal: true

module FinishedGoodsApp
  class PalletMovementsInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def move_pallet(pallet_number, location, location_scan_field) # rubocop:disable Metrics/AbcSize
      pallet = prod_repo.find_pallet_by_pallet_number(pallet_number)
      return validation_failed_response(messages: { pallet_number: ['Pallet does not exist'] }) unless pallet
      return failed_response("Cannot move pallet: #{pallet_number}. Pallet is on a tripsheet") if repo.exists?(:vehicle_job_units, stock_item_id: pallet[:id], offloaded_at: nil)

      location_id = locn_repo.resolve_location_id_from_scan(location, location_scan_field)
      return validation_failed_response(messages: { location: ['Location does not exist'] }) if location_id.nil_or_empty?

      repo.transaction do
        FinishedGoodsApp::MoveStock.call(AppConst::PALLET_STOCK_TYPE, pallet[:id], location_id, 'MOVE_PALLET', nil)
      end
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message("#{__method__} #{pallet_number}, Loc: #{location}"))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def move_deck_pallets(deck, deck_scan_field, location_to, location_to_scan_field) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      deck_id = locn_repo.resolve_location_id_from_scan(deck, deck_scan_field)
      return validation_failed_response(messages: { deck: ['deck location does not exist'] }) if deck_id.nil_or_empty?

      from_location_type = locn_repo.get_locations_type_code(deck_id)
      return failed_response("From location must be a #{AppConst::LOCATION_TYPES_COLD_BAY_DECK}. You scanned a: #{from_location_type}") unless from_location_type == AppConst::LOCATION_TYPES_COLD_BAY_DECK

      location_to_id = locn_repo.resolve_location_id_from_scan(location_to, location_to_scan_field)
      return validation_failed_response(messages: { location_to: ['location_to does not exist'] }) if location_to_id.nil_or_empty?

      return failed_response('Deck and To Location cannot be the same') unless deck_id != location_to_id

      return failed_response('Destination deck does not have enough empty positions') if locn_repo.get_locations_type_code(location_to_id) == AppConst::LOCATION_TYPES_COLD_BAY_DECK && num_plts_in_dec(deck_id) > num_empty_positions_in_dec(location_to_id)

      plts_to_move = locn_repo.get_deck_pallets(deck_id).find_all { |d| !d[:pallet_number].nil_or_empty? }.sort_by { |p| p[:pos] }
      return failed_response('From Deck is empty') if plts_to_move.empty?

      repo.transaction do
        plts_to_move.each do |p|
          res = FinishedGoodsApp::MoveStock.call(AppConst::PALLET_STOCK_TYPE, p[:pallet_id], location_to_id, 'MOVE_PALLET', nil)
          raise res.message unless res.success
        end
      end

      success_response('Pallets moved successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      # ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message("#{__method__} #{deck_id}, Loc: #{location_to_id}"))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def local_pallets_to_in_stock
      pallet_ids = repo.local_non_stock_pallets
      update_pallets_to_in_stock(pallet_ids)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def export_pallets_to_in_stock(pallet_ids)
      raise Crossbeams::InfoError, 'Can not allow pallets to bypass inspection' unless AppConst::ALLOW_EXPORT_PALLETS_TO_BYPASS_INSPECTION

      update_pallets_to_in_stock(pallet_ids)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_pallets_to_in_stock(pallet_ids)
      repo.transaction do
        repo.update(:pallets, pallet_ids, in_stock: true, stock_created_at: Time.now)
        log_multiple_statuses(:pallets, pallet_ids, 'ACCEPTED_AS_LOCAL_STOCK')
        log_transaction
      end
      success_response("Updated #{pallet_ids.length} pallets to in stock")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def set_pallets_target_customer(target_customer_id, pallet_ids)
      return failed_response('Target customer cannot be empty') if target_customer_id.nil_or_empty?

      repo.set_pallets_target_customer(target_customer_id, pallet_ids)

      success_response("Selected pallets have been successfully allocated to target customer #{get_target_customer_name(target_customer_id)}")
    end

    def pallets_in_location_to_be_cleared(params)
      location_id = locn_repo.resolve_location_id_from_scan(params[:location], params[:location_scan_field])
      return failed_response('Location does not exist') if location_id.nil_or_empty?

      location_code = repo.get_value(:locations, :location_short_code, id: location_id)
      pallet_count = locn_repo.location_pallets_count(location_id)
      return failed_response("Location: #{location_code} is empty") if pallet_count.zero?

      success_response("There are #{pallet_count} pallets in this location: #{location_code}. Are you sure these pallets are no longer there?", location_id)
    end

    def move_all_pallet_out_of_location(location_id) # rubocop:disable Metrics/AbcSize
      pending_location_id = repo.get_value(:locations, :id, location_short_code: AppConst::PENDING_LOCATION)
      pallets = repo.select_values(:pallets, :id, location_id: location_id)
      location_code = repo.get_value(:locations, :location_short_code, id: location_id)

      repo.transaction do
        pallets.each do |id|
          res = FinishedGoodsApp::MoveStock.call(AppConst::PALLET_STOCK_TYPE, id, pending_location_id, 'MOVE_PALLET', nil)
          raise Crossbeams::InfoError, res.message unless res.success
        end
      end

      success_response("#{pallets.size} pallets moved from #{location_code} to #{AppConst::PENDING_LOCATION}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def validate_location(scanned_location, location_scan_field)
      location_id = locn_repo.resolve_location_id_from_scan(scanned_location, location_scan_field)
      return validation_failed_response(messages: { location: ['Location does not exist'] }) if location_id.nil_or_empty?

      success_response('ok', location_id)
    end

    def location_short_code_for(location_id)
      repo.get(:locations, location_id, :location_short_code)
    end

    def validate_pallet_number(pallet_number)
      pallet = prod_repo.find_pallet_by_pallet_number(pallet_number)
      return validation_failed_response(messages: { pallet_number: ['Pallet does not exist'] }) unless pallet

      success_response('ok', pallet)
    end

    def move_location_pallet(pallet_id, location_id) # rubocop:disable Metrics/AbcSize
      repo.transaction do
        FinishedGoodsApp::MoveStock.call(AppConst::PALLET_STOCK_TYPE, pallet_id, location_id, 'MOVE_PALLET', nil)
      end
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message("#{__method__} #{pallet_number}, Loc: #{location}"))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    private

    def get_location_id_by_barcode(location_barcode)
      repo.get_location_id_by_barcode(location_barcode)
    end

    def num_plts_in_dec(deck_id)
      locn_repo.get_deck_pallets(deck_id).find_all { |d| !d[:pallet_number].nil_or_empty? }.length
    end

    def num_empty_positions_in_dec(deck_id)
      locn_repo.get_deck_pallets(deck_id).find_all { |d| d[:pallet_number].nil_or_empty? }.length
    end

    def get_target_customer_name(target_customer_id)
      party_repo.fn_party_role_name(target_customer_id)
    end

    def repo
      @repo ||= FinishedGoodsApp::LoadRepo.new
    end

    def locn_repo
      MasterfilesApp::LocationRepo.new
    end

    def party_repo
      @party_repo ||= MasterfilesApp::PartyRepo.new
    end

    def prod_repo
      @prod_repo ||= ProductionApp::ProductionRunRepo.new
    end
  end
end
