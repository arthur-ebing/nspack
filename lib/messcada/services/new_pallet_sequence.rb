# frozen_string_literal: true

module MesscadaApp
  class NewPalletSequence < BaseService
    attr_reader :repo, :carton_id, :carton_quantity, :pallet_id

    def initialize(carton_id, pallet_id, carton_quantity)
      @carton_id = carton_id
      @carton_quantity = carton_quantity
      @pallet_id = pallet_id
      @repo = MesscadaApp::MesscadaRepo.new
    end

    def call
      res = NewPalletSequenceObject.call(carton_id, carton_quantity)
      return res unless res.success

      repo.create_sequences(res.instance, pallet_id)

      ok_response
    end
  end
end
