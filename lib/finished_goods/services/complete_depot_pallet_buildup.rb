# frozen_string_literal: true

module FinishedGoodsApp
  class CompleteDepotPalletBuildup < BaseService
    attr_reader :repo, :depot_pallet_buildup, :user_name, :messcada_repo, :reworks_repo, :production_run_repo, :destination_pallet_number

    def initialize(depot_pallet_buildup_id, user_name)
      @repo = FinishedGoodsApp::BuildupsRepo.new
      @depot_pallet_buildup = repo.find_depot_pallet_buildup(depot_pallet_buildup_id)
      @user_name = user_name
      @messcada_repo = MesscadaApp::MesscadaRepo.new
      @reworks_repo = ProductionApp::ReworksRepo.new
      @production_run_repo = ProductionApp::ProductionRunRepo.new
      @destination_pallet_number = depot_pallet_buildup.destination_pallet_number
    end

    def call # rubocop:disable Metrics/AbcSize
      create_destination_pallet if depot_pallet_buildup.auto_create_destination_pallet
      move_cartons

      updates = { completed: true, completed_at: Time.now, destination_pallet_number: destination_pallet_number }
      repo.update(:depot_pallet_buildups, depot_pallet_buildup.id, updates)
      zero_qty_src_seqs = repo.select_values(:pallet_sequences, :id, id: depot_pallet_buildup.sequence_cartons_moved.keys, carton_quantity: 0)
      success_response("depot pallet buildup: #{depot_pallet_buildup.id} has been completed successfully", zero_qty_src_seqs.flatten)
    end

    private

    def create_destination_pallet # rubocop:disable Metrics/AbcSize
      rep_sequence_id = depot_pallet_buildup.sequence_cartons_moved.keys[0]
      rep_pallet_id = repo.get_value(:pallet_sequences, :pallet_id, id: rep_sequence_id)
      pallet = reworks_repo.get_pallet(rep_pallet_id)
      destination_pallet_id = reworks_repo.clone_pallet(pallet, [rep_sequence_id], user_name)
      repo.update(:pallets, destination_pallet_id, carton_quantity: 0)
      new_sequence_id = messcada_repo.matching_sequence(destination_pallet_id, rep_sequence_id)
      repo.update(:pallet_sequences, new_sequence_id, carton_quantity: 0)
      @destination_pallet_number = repo.get_value(:pallets, :pallet_number, id: destination_pallet_id)
    end

    def move_cartons # rubocop:disable Metrics/AbcSize
      destination_pallet_id = repo.get_value(:pallets, :id, pallet_number: destination_pallet_number)
      depot_pallet_buildup.sequence_cartons_moved.each do |sequence_id, ctn_qty_moved|
        unless messcada_repo.contains_sequence?(destination_pallet_id, sequence_id)
          src_pallet_id = repo.get_value(:pallet_sequences, :pallet_id, id: sequence_id)
          reworks_repo.clone_pallet_sequences(src_pallet_id, destination_pallet_id, [sequence_id], user_name)
          dest_sequence_id = messcada_repo.matching_sequence(destination_pallet_id, sequence_id)
          repo.update(:pallet_sequences, dest_sequence_id, carton_quantity: 0)
        end

        dest_sequence_id ||= messcada_repo.matching_sequence(destination_pallet_id, sequence_id)
        production_run_repo.increment_sequence_by(ctn_qty_moved, dest_sequence_id)
        production_run_repo.decrement_sequence_by(ctn_qty_moved, sequence_id)

        dest_pallet_number, dest_pallet_sequence_number = repo.depot_pallet_sequence(dest_sequence_id)
        src_pallet_number, src_pallet_sequence_number = repo.depot_pallet_sequence(sequence_id)
        repo.log_status('pallet_sequences', dest_sequence_id, AppConst::CARTON_TRANSFER, comment: "#{ctn_qty_moved} CTNS RECEIVED FROM #{src_pallet_number}, SEQUENCE #{src_pallet_sequence_number}", user_name: user_name)
        repo.log_status('pallet_sequences', sequence_id, AppConst::CARTON_TRANSFER, comment: "#{ctn_qty_moved} CTNS GIVEN TO #{dest_pallet_number}, SEQUENCE #{dest_pallet_sequence_number}", user_name: user_name)
      end
    end
  end
end
