# frozen_string_literal: true

module MesscadaApp
  class NewPalletSequence < BaseService
    attr_reader :repo, :carton_id, :carton_quantity, :pallet_id, :user_name, :carton_palletizing, :mix_rule_scope

    def initialize(user_name, carton_id, pallet_id, carton_quantity, carton_palletizing = false, mix_rule_scope = nil) # rubocop:disable Metrics/ParameterLists
      @mix_rule_scope = mix_rule_scope
      @carton_id = carton_id
      @carton_quantity = carton_quantity
      @pallet_id = pallet_id
      @repo = MesscadaApp::MesscadaRepo.new
      @user_name = user_name
      @carton_palletizing = carton_palletizing
    end

    def call # rubocop:disable Metrics/AbcSize
      res = NewPalletSequenceObject.call(user_name, carton_id, carton_quantity, carton_palletizing)
      return res unless res.success

      validations = validate_pallet_mix_rules(res.instance)
      return validations unless validations.success

      id = repo.create_sequences(res.instance, pallet_id)
      repo.update_carton(carton_id, { pallet_sequence_id: id }) if !carton_equals_pallet? && AppConst::USE_CARTON_PALLETIZING

      success_response('ok', pallet_sequence_id: id)
    end

    private

    def validate_pallet_mix_rules(new_sequence)
      oldest_sequence = repo.get_oldest_pallet_sequence(pallet_id)
      return ok_response unless oldest_sequence
      return ok_response unless mix_rule_scope

      carton_number = repo.get_value(:cartons, :carton_label_id, id: carton_id)
      ProductionApp::TaskPermissionCheck::PalletMixRule.call(mix_rule_scope, new_sequence, oldest_sequence, carton_number)
    end

    def carton_equals_pallet?
      carton_label_id = repo.get_value(:cartons, :carton_label_id, id: carton_id)
      repo.carton_label_carton_equals_pallet(carton_label_id)
    end
  end
end
