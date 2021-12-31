# frozen_string_literal: true

module FinishedGoodsApp
  class CalculateExtendedFgCodes < BaseService
    attr_reader :repo, :pallet_sequence_ids, :packing_specification_item_id, :pallet_ids

    def initialize(pallet_ids)
      @pallet_ids = pallet_ids
      @repo = ProductionApp::ProductSetupRepo.new
    end

    def call
      @pallet_ids = repo.select_values(:pallets, :id, id: pallet_ids, depot_pallet: false) # Make sure to exclude depot pallets
      packing_specification_item_ids = repo.select_values(:pallet_sequences,
                                                          :packing_specification_item_id,
                                                          { pallet_id: pallet_ids }).uniq

      packing_specification_item_ids.each do |packing_specification_item_id|
        @packing_specification_item_id = packing_specification_item_id
        @pallet_sequence_ids = repo.select_values(:pallet_sequences,
                                                  :id,
                                                  { pallet_id: pallet_ids,
                                                    packing_specification_item_id: packing_specification_item_id })
        calculate_extended_fg_codes
      end

      success_response('Extended FG codes calculated successfully')
    end

    private

    def calculate_extended_fg_codes
      extended_fg_code = nil
      extended_fg_id = nil

      ['-', '_'].each do |pm_join|
        extended_fg_code = repo.calculate_extended_fg_code(packing_specification_item_id, packaging_marks_join: pm_join)
        lkp = ProductionApp::LookupExtendedFgCodeId.call(extended_fg_code)
        extended_fg_id = lkp.instance || lkp.message
        break if lkp.success
      end

      args = { legacy_data: { extended_fg_code: extended_fg_code, extended_fg_id:  extended_fg_id } }
      pallet_sequence_ids.each do |id|
        update_pallet_sequence(id, args)
      end
    end

    def update_pallet_sequence(id, attrs)
      legacy_data = UtilityFunctions.symbolize_keys(repo.get(:pallet_sequences, :legacy_data, id).to_h)

      attrs[:legacy_data] = legacy_data.merge(attrs[:legacy_data].to_h)
      repo.update(:pallet_sequences, id, attrs)
    end
  end
end
