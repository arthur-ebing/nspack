# frozen_string_literal: true

module MesscadaApp
  class TransferBayCarton < BaseService
    attr_reader :repo, :prod_repo, :reworks_repo, :palletizing_repo, :carton_id, :pallet_id, :pallet_sequence_id, :original_pallet_id, :original_pallet_sequence_id

    def initialize(carton_id, pallet_id)
      @carton_id = carton_id
      @pallet_id = pallet_id
      @repo = MesscadaApp::MesscadaRepo.new
      @prod_repo = ProductionApp::ProductionRunRepo.new
      @reworks_repo = ProductionApp::ReworksRepo.new
      @palletizing_repo = MesscadaApp::PalletizingRepo.new
    end

    def call
      return failed_response("Pallet :#{pallet_id} does not exist") unless pallet_exists?

      return failed_response("Carton :#{carton_id} does not exist") unless carton_exists?

      @original_pallet_sequence_id = repo.get(:cartons, carton_id, :pallet_sequence_id)
      @original_pallet_id = repo.get(:pallet_sequences, original_pallet_sequence_id, :pallet_id)

      res = transfer_carton
      # raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success
      return res unless res.success

      success_response('ok', pallet_sequence_id: pallet_sequence_id)
    end

    private

    def pallet_exists?
      repo.exists?(:pallets, id: pallet_id)
    end

    def carton_exists?
      repo.carton_exists?(carton_id)
    end

    def transfer_carton # rubocop:disable Metrics/AbcSize
      new_sequence = NewSequence.new(pallet_id, carton_id).call
      if new_sequence
        res = NewPalletSequence.call(@user_name, carton_id, pallet_id, 1, true, AppConst::PALLETIZING_BAYS_PALLET_MIX)
        return res unless res.success

        @pallet_sequence_id = res.instance[:pallet_sequence_id]
      else
        @pallet_sequence_id = repo.matching_sequence_for_carton(carton_id, pallet_id)
        repo.update_carton(carton_id, { pallet_sequence_id: pallet_sequence_id })
        prod_repo.increment_sequence(pallet_sequence_id)
      end
      prod_repo.decrement_sequence(original_pallet_sequence_id) unless original_pallet_sequence_id.nil?
      remove_original_pallet_sequence if pallet_sequence_removed?
      repo.log_status('pallets', pallet_id, AppConst::CARTON_TRANSFER)
      repo.log_status('cartons', carton_id, AppConst::CARTON_TRANSFER)

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def pallet_sequence_removed?
      reworks_repo.pallet_sequence_carton_quantity(original_pallet_sequence_id).<= 0
    end

    def remove_original_pallet_sequence
      attrs = { removed_from_pallet: true,
                removed_from_pallet_at: Time.now,
                pallet_id: nil,
                removed_from_pallet_id: original_pallet_id,
                exit_ref: AppConst::SEQ_REMOVED_BY_CTN_TRANSFER }

      reworks_repo.update_pallet_sequence(original_pallet_sequence_id, attrs)
      repo.log_status('pallets', original_pallet_id, AppConst::SEQ_REMOVED_BY_CTN_TRANSFER)
      repo.log_status('pallet_sequences', original_pallet_sequence_id, AppConst::SEQ_REMOVED_BY_CTN_TRANSFER)
      scrap_original_pallet if scrap_carton_pallet?
    end

    def scrap_carton_pallet?
      reworks_repo.unscrapped_sequences_count(original_pallet_id).<= 0
    end

    def scrap_original_pallet
      attrs = { scrapped: true,
                scrapped_at: Time.now,
                exit_ref: AppConst::PALLET_EXIT_REF_SCRAPPED }
      reworks_repo.update_pallet(original_pallet_id, attrs)
      repo.log_status('pallets', original_pallet_id, AppConst::PALLET_SCRAPPED_BY_CTN_TRANSFER)
      update_scrapped_pallet_palletizing_bay_state
    end

    def update_scrapped_pallet_palletizing_bay_state
      changeset = { current_state: 'empty',
                    pallet_sequence_id: nil,
                    determining_carton_id: nil,
                    last_carton_id: nil }

      palletizing_repo.update_palletizing_bay_state(sequence_palletizing_bay_state, changeset)
    end

    def sequence_palletizing_bay_state
      palletizing_repo.pallet_sequence_palletizing_bay_state(original_pallet_sequence_id)
    end
  end
end
