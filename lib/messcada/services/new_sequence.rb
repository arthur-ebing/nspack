# frozen_string_literal: true

module MesscadaApp
  class NewSequence < BaseService
    attr_reader :repo, :pallet_id, :carton_id, :carton

    def initialize(pallet_id, carton_id)
      @pallet_id = pallet_id
      @carton_id = carton_id
      @repo = MesscadaApp::MesscadaRepo.new
    end

    def call
      return failed_response("Pallet :#{pallet_id} does not exist") unless pallet_exists?

      return failed_response("Carton :#{carton_id} does not exist") unless carton_exists?

      new_sequence?
    end

    private

    def pallet_exists?
      repo.exists?(:pallets, id: pallet_id)
    end

    def carton_exists?
      repo.carton_exists?(carton_id)
    end

    def new_sequence?
      repo.new_sequence?(carton_id, pallet_id)
    end
  end
end
