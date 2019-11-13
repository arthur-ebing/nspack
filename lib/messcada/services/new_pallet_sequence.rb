# frozen_string_literal: true

module MesscadaApp
  class NewPalletSequence < BaseService
    attr_reader :repo, :carton_id, :carton_quantity, :pallet_id

    def initialize(carton_id, carton_quantity, pallet_id)
      @carton_id = carton_id
      @carton_quantity = carton_quantity
      @pallet_id = pallet_id
      @repo = MesscadaApp::MesscadaRepo.new
    end

    def call
      res = NewPalletSequenceObject.new(carton_id, carton_quantity).call
      return res unless res.success

      repo.create_sequences(res.instance.to_h, pallet_id)

      ok_response
    end
  end
end
