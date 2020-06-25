# frozen_string_literal: true

module MesscadaApp
  class TransferBayCarton < BaseService
    attr_reader :repo, :carton_id, :pallet_id, :pallet_sequence_id

    def initialize(carton_id, pallet_id)
      @carton_id = carton_id
      @pallet_id = pallet_id
      @repo = MesscadaApp::MesscadaRepo.new
    end

    def call
      return failed_response("Pallet :#{pallet_id} does not exist") unless pallet_exists?

      return failed_response("Carton :#{carton_id} does not exist") unless carton_exists?

      res = transfer_carton
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      success_response('ok', pallet_sequence_id: pallet_sequence_id)
    end

    private

    def pallet_exists?
      repo.exists?(:pallets, id: pallet_id)
    end

    def carton_exists?
      repo.carton_exists?(carton_id)
    end

    def transfer_carton  # rubocop:disable Metrics/AbcSize
      new_sequence = NewSequence.new(pallet_id, carton_id).call
      if new_sequence
        res = NewPalletSequence.call(@user_name, carton_id, pallet_id, 1)
        return res unless res.success

        @pallet_sequence_id = res.instance[:pallet_sequence_id]
      else
        @pallet_sequence_id = repo.matching_sequence_for_carton(carton_id, pallet_id)
        repo.update_carton(carton_id, { pallet_sequence_id: pallet_sequence_id })
      end
      remove_sequence(original_carton_sequence) if sequence_removed?(original_carton_sequence)
      repo.log_status('pallets', pallet_id, AppConst::CARTON_TRANSFER)
      repo.log_status('cartons', carton_id, AppConst::CARTON_TRANSFER)

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def sequence_removed?(pallet_sequence_id)
      carton_quantity = repo.get(:pallet_sequences, pallet_sequence_id, :carton_quantity)
      carton_quantity.zero?
    end

    def original_carton_sequence
      repo.get(:cartons, carton_id, :pallet_sequence_id)
    end

    def remove_sequence(pallet_sequence_id)
      pallet_id = repo.get(:pallet_sequences, pallet_sequence_id, :pallet_id)

      attrs = { removed_from_pallet: true,
                removed_from_pallet_at: Time.now,
                pallet_id: nil,
                removed_from_pallet_id: pallet_id,
                exit_ref: AppConst::SEQ_REMOVED_BY_CTN_TRANSFER,
                exit_ref_date_time: Time.now }

      repo.update_pallet_sequence(pallet_sequence_id, attrs)
      repo.log_status('pallets', pallet_id, AppConst::SEQ_REMOVED_BY_CTN_TRANSFER)
      repo.log_status('pallet_sequences', pallet_sequence_id, AppConst::SEQ_REMOVED_BY_CTN_TRANSFER)
    end
  end
end
