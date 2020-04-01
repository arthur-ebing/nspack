# frozen_string_literal: true

module MesscadaApp
  class NewPalletSequence < BaseService
    attr_reader :repo, :carton_id, :carton_quantity, :pallet_id, :user_name

    def initialize(user_name, carton_id, pallet_id, carton_quantity)
      @carton_id = carton_id
      @carton_quantity = carton_quantity
      @pallet_id = pallet_id
      @repo = MesscadaApp::MesscadaRepo.new
      @user_name = user_name
    end

    def call
      res = NewPalletSequenceObject.call(user_name, carton_id, carton_quantity)
      return res unless res.success

      validations = validate_pallet_mix_rules(res.instance)
      return validations unless validations.success

      repo.create_sequences(res.instance, pallet_id)

      ok_response
    end

    private

    def validate_pallet_mix_rules(new_sequence) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      oldest_sequence = repo.get_oldest_pallet_sequence(pallet_id)
      return ok_response unless oldest_sequence

      rule = ProductionApp::ProductionRunRepo.new.find_pallet_mix_rules_by_scope(AppConst::GLOBAL_PALLET_MIX)
      return failed_response("Pallet tm_group:#{oldest_sequence[:target_market_group_name]}. You are adding a sequence with tm_group: #{repo.get(:target_market_groups, new_sequence[:packed_tm_group_id], :target_market_group_name)} . Mixing is not allowed") if !rule[:allow_tm_mix] && (new_sequence[:packed_tm_group_id] != oldest_sequence[:packed_tm_group_id])
      return failed_response("Pallet grade:#{oldest_sequence[:grade_code]}. You are adding a sequence with grade: #{repo.get(:grades, new_sequence[:grade_id], :grade_code)} . Mixing is not allowed") if !rule[:allow_grade_mix] && (new_sequence[:grade_id] != oldest_sequence[:grade_id])
      return failed_response("Pallet mark:#{oldest_sequence[:mark_code]}. You are adding a sequence with mark: #{repo.get(:marks, new_sequence[:mark_id], :mark_code)} . Mixing is not allowed") if !rule[:allow_mark_mix] && (new_sequence[:mark_id] != oldest_sequence[:mark_id])
      return failed_response("Pallet size_ref:#{oldest_sequence[:size_reference]}. You are adding a sequence with size_ref: #{repo.get(:fruit_size_references, new_sequence[:fruit_size_reference_id], :size_reference)} . Mixing is not allowed") if !rule[:allow_size_ref_mix] && (new_sequence[:fruit_size_reference_id] != oldest_sequence[:fruit_size_reference_id])
      return failed_response("Pallet pack:#{oldest_sequence[:standard_pack_code]}. You are adding a sequence with pack: #{repo.get(:standard_pack_codes, new_sequence[:standard_pack_code_id], :standard_pack_code)} . Mixing is not allowed") if !rule[:allow_pack_mix] && (new_sequence[:standard_pack_code_id] != oldest_sequence[:standard_pack_code_id])
      return failed_response("Pallet std_size_count:#{oldest_sequence[:size_count_value]}. You are adding a sequence with std_size_count: #{repo.get(:std_fruit_size_counts, new_sequence[:std_fruit_size_count_id], :size_count_value)} . Mixing is not allowed") if !rule[:allow_std_count_mix] && (new_sequence[:std_fruit_size_count_id] != oldest_sequence[:std_fruit_size_count_id])
      return failed_response("Pallet inventory_code:#{oldest_sequence[:inventory_code]}. You are adding a sequence with inventory_code: #{repo.get(:inventory_codes, new_sequence[:inventory_code_id], :inventory_code)} . Mixing is not allowed") if !rule[:allow_inventory_code_mix] && (new_sequence[:inventory_code_id] != oldest_sequence[:inventory_code_id])

      ok_response
    end
  end
end
