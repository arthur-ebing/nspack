# frozen_string_literal: true

module MesscadaApp
  class UpdatePalletSequence < BaseService
    attr_reader :repo, :pallet_id, :pallet_sequence_id, :carton_quantity

    def initialize(pallet_id, pallet_sequence_id, carton_quantity)
      @carton_quantity = carton_quantity
      @pallet_id = pallet_id
      @pallet_sequence_id = pallet_sequence_id
      @repo = MesscadaApp::MesscadaRepo.new
    end

    def call
      repo.update_pallet_sequence(pallet_sequence_id, carton_quantity: carton_quantity)

      repo.log_status('pallets', pallet_id, AppConst::PALLETIZED_SEQUENCE_UPDATED)
      ok_response
    end
  end
end
