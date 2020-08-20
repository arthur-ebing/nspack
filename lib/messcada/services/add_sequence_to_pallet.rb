# frozen_string_literal: true

module MesscadaApp
  class AddSequenceToPallet < BaseService
    attr_reader :repo, :carton_id, :carton_quantity, :pallet_id, :user_name, :mix_rule_scope

    def initialize(user_name, carton_id, pallet_id, carton_quantity, mix_rule_scope = nil)
      @carton_id = carton_id
      @carton_quantity = carton_quantity
      @pallet_id = pallet_id
      @repo = MesscadaApp::MesscadaRepo.new
      @user_name = user_name
      @mix_rule_scope = mix_rule_scope
    end

    def call
      res = NewPalletSequence.call(user_name, carton_id, pallet_id, carton_quantity, false, mix_rule_scope)
      return res unless res.success

      repo.log_status('pallets', pallet_id, AppConst::PALLETIZED_SEQUENCE_ADDED)
      ok_response
    end
  end
end
