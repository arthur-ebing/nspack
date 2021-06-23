# frozen_string_literal: true

module MesscadaApp
  module PalletFactory
    def create_pallet(opts = {}) # rubocop:disable Metrics/AbcSize
      # id = get_available_factory_record(:pallets, opts)
      # return id unless id.nil?

      default = {
        pallet_number: Faker::Lorem.unique.word,
        exit_ref: Faker::Lorem.word,
        scrapped_at: '2010-01-01 12:00',
        location_id: create_location,
        shipped: false,
        in_stock: false,
        inspected: false,
        shipped_at: '2010-01-01 12:00',
        govt_first_inspection_at: '2010-01-01 12:00',
        govt_reinspection_at: '2010-01-01 12:00',
        stock_created_at: '2010-01-01 12:00',
        phc: Faker::Lorem.word,
        intake_created_at: '2010-01-01 12:00',
        first_cold_storage_at: '2010-01-01 12:00',
        build_status: Faker::Lorem.word,
        gross_weight: Faker::Number.decimal,
        gross_weight_measured_at: '2010-01-01 12:00',
        palletized: false,
        partially_palletized: false,
        palletized_at: '2010-01-01 12:00',
        partially_palletized_at: '2010-01-01 12:00',
        fruit_sticker_pm_product_id: create_pm_product,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        allocated: false,
        allocated_at: '2010-01-01 12:00',
        reinspected: false,
        scrapped: false,
        pallet_format_id: create_pallet_format,
        carton_quantity: Faker::Number.number(digits: 4),
        govt_inspection_passed: false,
        plt_packhouse_resource_id: create_plant_resource,
        plt_line_resource_id: create_plant_resource,
        nett_weight: Faker::Number.decimal,
        load_id: create_load,
        fruit_sticker_pm_product_2_id: create_pm_product,
        last_govt_inspection_pallet_id: nil,
        temp_tail: Faker::Lorem.word,
        depot_pallet: false,
        edi_in_transaction_id: nil,
        edi_in_consignment_note_number: Faker::Lorem.word,
        re_calculate_nett: false,
        edi_in_inspection_point: Faker::Lorem.word,
        repacked: false,
        repacked_at: '2010-01-01 12:00',
        palletizing_bay_resource_id: create_plant_resource,
        has_individual_cartons: false,
        nett_weight_externally_calculated: false,
        legacy_data: BaseRepo.new.hash_for_jsonb_col({}),
        verified: false,
        verified_at: '2010-01-01 12:00',
        derived_weight: false
      }
      DB[:pallets].insert(default.merge(opts))
    end
  end
end
