# frozen_string_literal: true

module MesscadaApp
  class AddCartonToPallet < BaseService
    attr_reader :repo, :prod_repo, :carton_id, :pallet_id, :pallet_sequence_id, :mix_rule_scope

    def initialize(carton_id, pallet_id, mix_rule_scope = nil)
      @carton_id = carton_id
      @pallet_id = pallet_id
      @mix_rule_scope = mix_rule_scope
      @repo = MesscadaApp::MesscadaRepo.new
      @prod_repo = ProductionApp::ProductionRunRepo.new
    end

    def call
      return failed_response("Pallet :#{pallet_id} does not exist") unless pallet_exists?

      return failed_response("Carton :#{carton_id} does not exist") unless carton_exists?

      return failed_response("Carton :#{carton_id} already on a pallet") unless carton_is_available?

      res = add_carton_to_pallet
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

    def carton_is_available?
      repo.carton_pallet_sequence(carton_id).nil?
    end

    def add_carton_to_pallet  # rubocop:disable Metrics/AbcSize
      new_sequence = NewSequence.call(pallet_id, carton_id)
      if new_sequence
        res = NewPalletSequence.call(@user_name, carton_id, pallet_id, 1, true, mix_rule_scope)
        return res unless res.success

        @pallet_sequence_id = res.instance[:pallet_sequence_id]
      else
        @pallet_sequence_id = repo.matching_sequence_for_carton(carton_id, pallet_id)
        repo.update_carton(carton_id, { pallet_sequence_id: pallet_sequence_id })
        prod_repo.increment_sequence(pallet_sequence_id)
      end

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end
  end
end
