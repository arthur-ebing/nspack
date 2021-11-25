# frozen_string_literal: true

module FinishedGoodsApp
  class BuildupsInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def buildup_depot_pallet(params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      res = validate_pallet_buildup_params(params)
      return validation_failed_response(res) if res.failure?

      pallets = res.to_h.select { |k, v| (k.to_s.match(/^p\d+$/) || (k == :pallet_number)) && !v.to_s.empty? }.values.compact

      err = validate_pallets_exist(pallets)
      return validation_failed_response(messages: error_messages(res.to_h, err, "doesn't exist")) unless err.empty?

      err = validate_duplicate_scans(pallets)
      return validation_failed_response(messages: error_messages(res.to_h, err, 'is duplicate scan')) unless err.empty?

      err = validate_depot_pallets_not_busy(pallets)
      return validation_failed_response(messages: error_messages(res.to_h, err, 'is busy')) unless err.empty?

      err = validate_shipped(pallets)
      return validation_failed_response(messages: error_messages(res.to_h, err, 'is shipped')) unless err.empty?

      err = validate_scrapped(pallets)
      return validation_failed_response(messages: error_messages(res.to_h, err, 'is scrapped')) unless err.empty?

      err = validate_zero_qty(pallets)
      return validation_failed_response(messages: error_messages(res.to_h, err, 'has 0 ctn_qty')) unless err.empty?

      src_plts = res.to_h.select { |k, v| k.to_s.match(/^p\d+$/) && !v.to_s.empty? }.values.compact
      return failed_response("There's not enough cartons to move") unless src_pallets_have_enough_cartons?(src_plts, res[:qty_to_move])

      err = validate_has_no_individual_cartons(pallets)
      return validation_failed_response(messages: error_messages(res.to_h, err, 'has individuals ctns')) unless err.empty?

      id = nil
      repo.transaction do
        id = repo.create_depot_pallet_buildup(auto_create_destination_pallet: res[:auto_create_destination_pallet],
                                              destination_pallet_number: res[:pallet_number], source_pallets: "{#{src_plts.join(',')}}",
                                              qty_cartons_to_move: res[:qty_to_move], created_by: @user.user_name, sequence_cartons_moved: {})
        log_status(:depot_pallet_buildups, id, 'CREATED')
        log_transaction
      end
      destination_pallet_number = repo.get_value(:depot_pallet_buildups, :destination_pallet_number, id: id)
      success_response("Created depot pallet buildup #{destination_pallet_number}", id)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { destination_pallet_number: ['This depot pallet buildup already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def move_sequence_cartons(depot_pallet_buildup_id, params) # rubocop:disable Metrics/AbcSize
      error_msgs = {}
      sequence_cartons_moved = {}
      params.each do |k, v|
        next if v.to_i.zero?

        pallet_number, pallet_sequence_number = k.to_s.split('_')
        id, seq_ctn_qty = repo.depot_pallet_sequence_carton_quantity(pallet_number, pallet_sequence_number)
        error_msgs.store(k, ["qty to move(#{v}) exceeds seq ctn qty"]) unless v.to_i <= seq_ctn_qty
        sequence_cartons_moved.store(id, v.to_i)
      end
      return validation_failed_response(messages: error_msgs) unless error_msgs.empty?

      ctns_to_move = repo.get_value(:depot_pallet_buildups, :qty_cartons_to_move, id: depot_pallet_buildup_id)
      ctns_scanned = sequence_cartons_moved.values.sum
      return failed_response("You have scanned more cartons: #{ctns_scanned} than you planned to move: #{ctns_to_move}") unless ctns_scanned <= ctns_to_move

      repo.transaction do
        repo.update(:depot_pallet_buildups, depot_pallet_buildup_id, sequence_cartons_moved: sequence_cartons_moved)
        success_response('ok')
      end
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def complete_depot_buildup_message(depot_pallet_buildup_id)
      depot_pallet_buildup = repo.find_depot_pallet_buildup(depot_pallet_buildup_id)
      ctns_scanned = depot_pallet_buildup.sequence_cartons_moved.values.sum
      "#{ctns_scanned} cartons scanned, #{depot_pallet_buildup.qty_cartons_to_move - ctns_scanned} remaining. Complete?"
    end

    def complete_depot_pallet_buildup(id) # rubocop:disable Metrics/AbcSize
      depot_pallet_buildup = repo.find_depot_pallet_buildup(id)
      ctns_scanned = depot_pallet_buildup.sequence_cartons_moved.values.sum
      if ctns_scanned.zero?
        delete_depot_pallet_buildup(id)
        return success_response("#{ctns_scanned} cartons scanned. Depot pallet buildup #{id} has been cancelled")
      end

      repo.transaction do
        res = CompleteDepotPalletBuildup.call(id, @user.user_name)
        res.instance.each do |zero_seq|
          remove_sequence_from_pallet(zero_seq)
        end

        depot_pallet_buildup = repo.find_depot_pallet_buildup(id)
        if AppConst::CR_FG.lookup_extended_fg_code?
          pallet_ids = repo.select_values(:pallets, :id, pallet_number: [depot_pallet_buildup.destination_pallet_number] + depot_pallet_buildup.source_pallets)
          FinishedGoodsApp::Job::CalculateExtendedFgCodesFromSeqs.enqueue(pallet_ids)
        end
        res
      end
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Crossbeams::FrameworkError => e
      failed_response(e.message)
    end

    def delete_depot_pallet_buildup(id)
      repo.transaction do
        repo.delete_depot_pallet_buildup(id)
        log_status(:depot_pallet_buildups, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted depot pallet buildup #{id}")
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def process_to_rejoin(params)
      dest = params[:pallet_number]
      pallet_keys = (1..10).map { |n| "p#{n}".to_sym }
      src_plts = params.values_at(*pallet_keys).grep_v('').compact
      repo.get_process_to_rejoin(dest, src_plts, @user.user_name)
    end

    def process_to_cancel(params)
      pallet_keys = (1..10).map { |n| "p#{n}".to_sym } + [:pallet_number]
      pallets = params.values_at(*pallet_keys).grep_v('').compact
      if (uncompleted_process = repo.get_process_to_cancel(pallets, @user.user_name))
        return success_response('', { process: uncompleted_process, pallets: (uncompleted_process[:source_pallets] + [uncompleted_process[:destination_pallet_number]]) & pallets })
      end

      failed_response('no uncompleted processes found')
    end

    def buildup_pallet(params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      res = validate_pallet_buildup_params(params)
      return validation_failed_response(res) if res.failure?

      pallets = res.to_h.select { |k, v| (k.to_s.match(/^p\d+$/) || (k == :pallet_number)) && !v.to_s.empty? }.values.compact

      err = validate_pallets_exist(pallets)
      return validation_failed_response(messages: error_messages(res.to_h, err, "doesn't exist")) unless err.empty?

      err = validate_duplicate_scans(pallets)
      return validation_failed_response(messages: error_messages(res.to_h, err, 'is duplicate scan')) unless err.empty?

      err = validate_shipped(pallets)
      return validation_failed_response(messages: error_messages(res.to_h, err, 'is shipped')) unless err.empty?

      err = validate_scrapped(pallets)
      return validation_failed_response(messages: error_messages(res.to_h, err, 'is scrapped')) unless err.empty?

      err = validate_has_individual_cartons(pallets)
      return validation_failed_response(messages: error_messages(res.to_h, err, 'has no individuals ctns')) unless err.empty?

      err = validate_zero_qty(pallets)
      return validation_failed_response(messages: error_messages(res.to_h, err, 'has 0 ctn_qty')) unless err.empty?

      err = validate_pallets_not_busy(pallets)
      return validation_failed_response(messages: error_messages(res.to_h, err, 'is busy')) unless err.empty?

      src_plts = res.to_h.select { |k, v| k.to_s.match(/^p\d+$/) && !v.to_s.empty? }.values.compact
      return failed_response("There's not enough cartons to move") unless src_pallets_have_enough_cartons?(src_plts, res[:qty_to_move])

      id = nil
      repo.transaction do
        id = repo.create_pallet_buildup(auto_create_destination_pallet: res[:auto_create_destination_pallet], destination_pallet_number: res[:pallet_number], source_pallets: "{#{src_plts.join(',')}}", qty_cartons_to_move: res[:qty_to_move], created_by: @user.user_name, cartons_moved: {})
        log_transaction
      end
      instance = pallet_buildup(id)
      success_response("Created pallet buildup #{instance.destination_pallet_number}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def move_carton(params, pallet_buildup_id) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return validation_failed_response(messages: { carton_number: ['field cannot be empty'] }) if params[:carton_number].nil_or_empty?

      res = MesscadaApp::ScanCartonLabelOrPallet.call(params[:carton_number])
      return validation_failed_message_response(res.message) unless res.success

      params[:carton_number] = res.instance.carton_label_id
      carton = ProductionApp::ProductionRunRepo.new.find_carton_by_carton_label_id(params[:carton_number])
      return failed_response("Carton:#{params[:carton_number]} does not exist") unless carton
      return failed_response("Carton:#{params[:carton_number]} does not belong to any of the source pallets") unless repo.buildup_carton?(params[:carton_number], pallet_buildup_id)

      # Remove Carton
      pallet_buildup = pallet_buildup(pallet_buildup_id)
      if (pallet = pallet_buildup.cartons_moved.find { |_k, v| v.include?(params[:carton_number]) })
        pallet_buildup.cartons_moved[pallet[0]].delete(params[:carton_number])
        pallet_buildup.cartons_moved.delete(pallet[0]) if pallet_buildup.cartons_moved[pallet[0]].to_a.empty?
      else
        # Add Carton
        pallet_number = repo.find_pallet_by_carton_label_id(params[:carton_number])
        pallet_buildup.cartons_moved.store(pallet_number, []) unless pallet_buildup.cartons_moved[pallet_number]
        pallet_buildup.cartons_moved[pallet_number].push(params[:carton_number])
      end
      repo.update(:pallet_buildups, pallet_buildup_id, cartons_moved: pallet_buildup.cartons_moved)

      success_response('ok', pallet_buildup)
    end

    def delete_pallet_buildup(id)
      repo.transaction do
        repo.delete_pallet_buildup(id)
        log_transaction
      end
      success_response("Deleted pallet buildup #{id}")
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete pallet buildup. It is still referenced#{e.message.partition('referenced').last}")
    end

    def complete_pallet_buildup(id) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity,  Metrics/PerceivedComplexity
      repo.transaction do # rubocop:disable Metrics/BlockLength
        pallet_buildup = pallet_buildup(id)
        updates = { completed: true, completed_at: Time.now }
        unless pallet_buildup.completed
          if !pallet_buildup.destination_pallet_number.nil?
            dest_pallet_id = repo.get_value(:pallets, :id, pallet_number: pallet_buildup.destination_pallet_number)
          else
            creator_ctn_label = pallet_buildup.cartons_moved.first[1][0]
            carton_id, orig_seq = repo.select_values(:cartons, %i[id pallet_sequence_id], carton_label_id: creator_ctn_label).flatten
            res = MesscadaApp::CreatePalletFromCarton.new(@user, carton_id, 1).call
            return res unless res.success

            prod_run_repo.decrement_sequence(orig_seq)
            dest_pallet_id = res.instance[:pallet_id]
            repo.update(:pallets, dest_pallet_id, has_individual_cartons: true)
            updates.store(:destination_pallet_number, repo.get_value(:pallets, :pallet_number, id: dest_pallet_id))
          end

          pallet_buildup.cartons_moved.each do |_k, v|
            v.each do |cl_id|
              unless cl_id == creator_ctn_label
                orig_seq = repo.get_value(:cartons, :pallet_sequence_id, carton_label_id: cl_id)
                res = MesscadaApp::TransferCarton.call(prod_run_repo.find_carton_by_carton_label_id(cl_id)[:id], dest_pallet_id, @user.user_name)
                raise Crossbeams::InfoError, res.message unless res.success
              end

              remove_sequence_from_pallet(orig_seq) if repo.get_value(:pallet_sequences, :carton_quantity, id: orig_seq).zero?
            end
          end

          repo.update(:pallet_buildups, id, updates)
        end

        if AppConst::CR_FG.lookup_extended_fg_code?
          pallet_ids = repo.select_values(:pallets, :id, pallet_number: [pallet_buildup.destination_pallet_number] + pallet_buildup.source_pallets)
          FinishedGoodsApp::Job::CalculateExtendedFgCodesFromSeqs.enqueue(pallet_ids)
        end

        success_response("Pallet buildup:#{id} has been completed successfully")
      end
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def pallet_buildup(id)
      repo.find_pallet_buildup(id)
    end

    def depot_pallet_buildup(id)
      repo.find_depot_pallet_buildup(id)
    end

    def depot_buildup_pallet_sequences(pallet_number)
      repo.depot_buildup_pallet_sequences(pallet_number)
    end

    private

    def remove_sequence_from_pallet(src_seq_id)
      src_pallet_id = repo.get_value(:pallet_sequences, :pallet_id, id: src_seq_id)
      src_pallet_ctn_qty = repo.get_value(:pallets, :carton_quantity, id: src_pallet_id)
      attrs = { removed_from_pallet: true,
                removed_from_pallet_at: Time.now,
                pallet_id: nil,
                removed_from_pallet_id: src_pallet_id,
                exit_ref: AppConst::SEQ_REMOVED_BY_CTN_TRANSFER }

      reworks_repo.update_pallet_sequence(src_seq_id, attrs)
      repo.log_status('pallets', src_pallet_id, AppConst::SEQ_REMOVED_BY_CTN_TRANSFER)
      repo.log_status('pallet_sequences', src_seq_id, AppConst::SEQ_REMOVED_BY_CTN_TRANSFER)
      scrap_src_pallet(src_pallet_id) if src_pallet_ctn_qty.zero?
    end

    def scrap_src_pallet(src_pallet_id)
      attrs = { scrapped: true,
                scrapped_at: Time.now,
                exit_ref: AppConst::PALLET_EXIT_REF_SCRAPPED }
      reworks_repo.update_pallet(src_pallet_id, attrs)
      repo.log_status('pallets', src_pallet_id, AppConst::PALLET_SCRAPPED_BY_CTN_TRANSFER)
    end

    def validate_pallet_buildup_params(params)
      res = PalletBuildupContract.new.call(params)
      return res if res.failure?

      # Resolve the scanned pallets (remove "00" prefix etc.)
      invalid_pallets, new_params = build_new_params_with_scanned_pallet_nos(params)

      raise Crossbeams::InfoError, invalid_pallets.join("\n") unless invalid_pallets.empty?

      PalletBuildupContract.new.call(new_params)
    end

    def build_new_params_with_scanned_pallet_nos(params)
      new_params = {}
      invalid_pallets = []
      params.each do |k, v|
        if (k.to_s.match(/^p\d+$/) || (k == :pallet_number)) && !v.to_s.empty?
          scan_res = MesscadaApp::ScanCartonLabelOrPallet.call(scanned_number: v, expect: :pallet_number)
          p scan_res
          invalid_pallets << scan_res.message unless scan_res.success
          new_params[k] = scan_res.success ? scan_res.instance.pallet_number : v
        else
          new_params[k] = v
        end
      end
      [invalid_pallets, new_params]
    end

    def validate_shipped(pallets)
      repo.get_shipped(pallets)
    end

    def validate_scrapped(pallets)
      repo.get_scrapped(pallets)
    end

    def validate_has_individual_cartons(pallets)
      repo.get_has_no_individual_cartons(pallets)
    end

    def validate_has_no_individual_cartons(pallets)
      repo.get_has_individual_cartons(pallets)
    end

    def validate_zero_qty(pallets)
      repo.get_zero_qty_pallets(pallets)
    end

    def validate_pallets_not_busy(pallets)
      repo.get_build_up_pallets(pallets)
    end

    def validate_depot_pallets_not_busy(pallets)
      repo.get_depot_build_up_pallets(pallets)
    end

    def validate_pallets_exist(pallets)
      pallets - repo.get_pallets(pallets)
    end

    def validate_duplicate_scans(pallets)
      pallets.find_all { |e| pallets.count(e) > 1 }.uniq
    end

    def src_pallets_have_enough_cartons?(src_plts, qty_to_move)
      repo.pallets_ctn_qty_sum(src_plts) >= qty_to_move
    end

    def error_messages(params, pallets, status)
      errors = {}
      pallets.each do |p|
        params.find_all { |_k, v| v == p }.each do |pp|
          errors.store(pp[0], ["#{pp[1]} #{status}"])
        end
      end
      errors
    end

    def repo
      @repo ||= BuildupsRepo.new
    end

    def prod_run_repo
      ProductionApp::ProductionRunRepo.new
    end

    def reworks_repo
      ProductionApp::ReworksRepo.new
    end
  end
end
