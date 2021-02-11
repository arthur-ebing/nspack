# frozen_string_literal: true

module FinishedGoodsApp
  class CalculateExtendedFgCodes < BaseService
    attr_accessor :pallets

    def initialize(pallets)
      @pallets = pallets
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

    def calculate_extended_fg_codes # rubocop:disable Metrics/AbcSize
      seq_extended_fgs = []
      repo.all_hash(:pallet_sequences, pallet_id: pallets).each do |s|
        seq_extended_fgs << { id: s[:id], extended_fg_code: calculate_extended_fg_code(s[:packing_specification_item_id]) }
      end

      seq_extended_fgs.group_by { |h| h[:extended_fg_code] }.each do |k, v|
        extended_fg_id = MesscadaApp::MesscadaRepo.new.extended_fg_id(k)
        v.each do |s|
          MesscadaApp::MesscadaRepo.new.update_pallet_sequence_extended_fg(s[:id], k, extended_fg_id)
        end
      end
    end

    def calculate_extended_fg_code(packing_specification_item_id) # rubocop:disable Metrics/AbcSize
      prod_setup = repo.packing_specification_item_prod_setup(packing_specification_item_id)
      fg_code_components = []
      fg_code_components << repo.prod_setup_commodity_code(prod_setup[:id])
      fg_code_components << MasterfilesApp::CultivarRepo.new.find_marketing_variety(prod_setup[:marketing_variety_id])&.marketing_variety_code
      fg_code_components << MasterfilesApp::FruitRepo.new.find_rmt_class(prod_setup[:rmt_class_id])&.rmt_class_code
      fg_code_components << MasterfilesApp::FruitRepo.new.find_grade(prod_setup[:grade_id])&.grade_code
      fg_code_components << MasterfilesApp::FruitSizeRepo.new.find_fruit_actual_counts_for_pack(prod_setup[:fruit_actual_counts_for_pack_id])&.actual_count_for_pack
      fg_code_components << MasterfilesApp::FruitRepo.new.find_inventory_code(prod_setup[:inventory_code_id])&.inventory_code
      fg_code_components << MasterfilesApp::FruitSizeRepo.new.find_fruit_size_reference(prod_setup[:fruit_size_reference_id])&.size_reference
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
  end
end
