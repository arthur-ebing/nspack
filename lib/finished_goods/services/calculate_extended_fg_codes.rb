# frozen_string_literal: true

module FinishedGoodsApp
  class CalculateExtendedFgCodes < BaseService
    attr_accessor :pallet_ids

    def initialize(pallet_ids)
      @pallet_ids = pallet_ids
    end

    def call
      repo.transaction do
        calculate_extended_fg_codes
      end

      success_response('Extended FG codes calculated successfully')
    rescue StandardError => e
      failed_response(e.message)
    end

    private

    def calculate_extended_fg_codes
      seq_extended_fgs = []
      repo.select_values(:pallet_sequences, %i[id packing_specification_item_id], pallet_id: pallet_ids).each do |id, packing_specification_item_id|
        seq_extended_fgs << { id: id, extended_fg_code: calculate_extended_fg_code(packing_specification_item_id) }
      end

      ms_repo = MesscadaApp::MesscadaRepo.new
      seq_extended_fgs.group_by { |h| h[:extended_fg_code] }.each do |k, v|
        extended_fg_id = ms_repo.extended_fg_id(k)
        v.each do |s|
          ms_repo.update_pallet_sequence_extended_fg(s[:id], k, extended_fg_id)
        end
      end
    end

    def calculate_extended_fg_code(packing_specification_item_id) # rubocop:disable Metrics/AbcSize
      prod_setup = repo.packing_specification_item_prod_setup(packing_specification_item_id)
      fg_code_components = []
      fg_code_components << repo.prod_setup_commodity_code(prod_setup[:id])
      fg_code_components << MasterfilesApp::CultivarRepo.new.find_marketing_variety(prod_setup[:marketing_variety_id])&.marketing_variety_code
      fg_code_components << fruit_repo.find_rmt_class(prod_setup[:rmt_class_id])&.rmt_class_code
      fg_code_components << fruit_repo.find_grade(prod_setup[:grade_id])&.grade_code
      fg_code_components << fruit_size_repo.find_fruit_actual_counts_for_pack(prod_setup[:fruit_actual_counts_for_pack_id])&.actual_count_for_pack
      fg_code_components << fruit_repo.find_inventory_code(prod_setup[:inventory_code_id])&.inventory_code
      fg_code_components << fruit_size_repo.find_fruit_size_reference(prod_setup[:fruit_size_reference_id])&.size_reference
      fg_code_components << repo.packing_specification_item_units_per_carton(packing_specification_item_id).to_f
      fg_code_components << repo.packing_specification_item_unit_pack_product(packing_specification_item_id)
      fg_code_components << repo.packing_specification_item_carton_pack_product(packing_specification_item_id)
      fg_code_components << repo.prod_setup_organisation(prod_setup[:id])
      fg_code_components << repo.packing_specification_item_fg_marks(packing_specification_item_id)
      fg_code_components.join('_')
    end

    def repo
      @repo ||= ProductionApp::ProductSetupRepo.new
    end

    def fruit_size_repo
      @fruit_size_repo ||= MasterfilesApp::FruitSizeRepo.new
    end

    def fruit_repo
      @fruit_repo ||= MasterfilesApp::FruitRepo.new
    end
  end
end
