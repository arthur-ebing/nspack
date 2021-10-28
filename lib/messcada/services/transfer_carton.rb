# frozen_string_literal: true

module MesscadaApp
  class TransferCarton < BaseService
    attr_reader :repo, :prod_repo, :carton_id, :pallet_id, :pallet_sequence_id

    def initialize(carton_id, pallet_id)
      @carton_id = carton_id
      @pallet_id = pallet_id
      @repo = MesscadaApp::MesscadaRepo.new
      @prod_repo = ProductionApp::ProductionRunRepo.new
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

    def transfer_carton # rubocop:disable Metrics/AbcSize
      orig_seq = repo.get_value(:cartons, :pallet_sequence_id, id: carton_id)
      new_sequence = NewSequence.new(pallet_id, carton_id).call
      if new_sequence
        res = NewPalletSequence.call(@user_name, carton_id, pallet_id, 1, true, AppConst::BUILDUP_PALLET_MIX)
        return res unless res.success

        @pallet_sequence_id = res.instance[:pallet_sequence_id]
      else
        @pallet_sequence_id = repo.matching_sequence_for_carton(carton_id, pallet_id)
        prod_repo.increment_sequence(pallet_sequence_id)
      end

      repo.update_carton(carton_id, { pallet_sequence_id: pallet_sequence_id })
      prod_repo.decrement_sequence(orig_seq)

      repo.log_status('pallets', pallet_id, AppConst::CARTON_TRANSFER)
      repo.log_status('cartons', carton_id, AppConst::CARTON_TRANSFER)
      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end
  end
end
